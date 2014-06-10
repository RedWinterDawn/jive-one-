//
//  JCSocketDispatch.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 2/14/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCSocketDispatch.h"
#import "JCOsgiClient.h"
#import "KeychainItemWrapper.h"
#import "ConversationEntry+Custom.h"
#import "Voicemail+Custom.h"
#import "Presence+Custom.h"
#import "JCAppDelegate.h"
#import "JSMessageSoundEffect.h"

@interface JCSocketDispatch()

{
    BOOL startedInBackground;
    BOOL didSignalToCloseSocket;
}

@property (strong, nonatomic) NSDictionary* cmd_start;
@property (strong, nonatomic) NSDictionary* cmd_poll;
@property (strong, nonatomic) NSString *json_start;
@property (strong, nonatomic) NSString *json_poll;
@property (strong, nonatomic) NSString* ws;
@property (strong, nonatomic) NSString* pipedTokens;
@property (strong, nonatomic) NSString *sessionToken;
@property (strong, nonatomic) NSString *deviceToken; //used for sending a push notification to restore the session if lost
@property (strong, nonatomic) NSTimer *socketSessionTimer;
@property (strong, nonatomic) NSTimer *subscriptionTimer;

@end

@implementation JCSocketDispatch



+ (instancetype)sharedInstance
{
    static JCSocketDispatch * sharedObject = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedObject = [[super alloc] init];
    });
    
    return sharedObject;
}



#pragma mark - Public Methods
- (void)sendPoll
{
    if (_webSocket.readyState == SR_OPEN) {
        [_webSocket send:self.json_poll];
    }
}

/**
 *  Fires a request to the server where it retreives a session token used to connect to the websocket
 *  if the user is authenticated.
 *
 */
- (void)requestSession
{
    
    NSLog(@"Requestion Session For Socket");
    startedInBackground = [UIApplication sharedApplication].applicationState == (UIApplicationStateBackground|UIApplicationStateInactive);
    [self cleanup];
    
    if ([[JCAuthenticationManager sharedInstance] userAuthenticated] )  {
        
        [[JCOsgiClient sharedClient] RequestSocketSession:^(id JSON) {
            
            if (_socketSessionTimer) {
                [_socketSessionTimer invalidate];
            }
            
            // First, get our current auth token
            NSString* authToken = [[JCAuthenticationManager sharedInstance] getAuthenticationToken];
            
            // From our response dictionary we'll get some info
            NSDictionary* response = (NSDictionary*)JSON;
            
            // Retrive session token and pipe it together with our auth token
            self.sessionToken = [NSString stringWithFormat:@"%@",[response objectForKey:@"token"]];
            self.pipedTokens = [NSString stringWithFormat:@"%@|%@", authToken, self.sessionToken];
            
            // Create dictionaries that will be converted to JSON objects to be posted to the socket.
            self.cmd_start = [NSDictionary dictionaryWithObjectsAndKeys:@"start", @"cmd", authToken, @"authToken", self.sessionToken, @"sessionToken", nil];
            self.cmd_poll  = [NSDictionary dictionaryWithObjectsAndKeys:@"poll", @"cmd", authToken, @"authToken", self.sessionToken, @"sessionToken", nil];
            
            NSError* error;
            // json start creation
            NSData* jsonData = [NSJSONSerialization dataWithJSONObject:self.cmd_start options:NSJSONWritingPrettyPrinted error:&error];
            self.json_start = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            // json poll creation
            jsonData = [NSJSONSerialization dataWithJSONObject:self.cmd_poll options:NSJSONWritingPrettyPrinted error:&error];
            self.json_poll = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            
            
            // Retrieve the ws parameter - this is the endpoint used to connect to our socket.
            self.ws = [response objectForKey:@"ws"];
            
            NSLog(@"Requestion Session For Socket : Success");
            
            // If we have everyting we need, we can subscribe to events.
            if (self.ws && self.sessionToken) {
                [self initSession];
            }
            
        } failure:^(NSError *err) {
            NSLog(@"Requestion Session For Socket : Failed");
            
            // if we fail to get a session, then try again in 2 seconds
            if (![_socketSessionTimer isValid]) {
                _socketSessionTimer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(socketSessionTimerElapsed:) userInfo:nil repeats:YES];
                [[NSRunLoop currentRunLoop] addTimer:_socketSessionTimer forMode:NSDefaultRunLoopMode];
            }
            
        }];
    }    
}

- (void)timesUpforSubscription
{
    [_subscriptionTimer invalidate];
    [_webSocket closeWithCode:500 reason:@"Did not subscribe to all events. Retrying"];
}

- (void)subscribeSession
{
    
    _subscriptionTimer = [NSTimer timerWithTimeInterval:4 target:self selector:@selector(timesUpforSubscription) userInfo:nil repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:_subscriptionTimer forMode:NSDefaultRunLoopMode];
    
    NSLog(@"Subscribing to Socket Events");
    
    NSDictionary* presence = [NSDictionary dictionaryWithObjectsAndKeys:@"presence:entities:*", @"urn", nil];
    NSDictionary* calls = [NSDictionary dictionaryWithObjectsAndKeys:@"calls:#", @"urn", nil];
    NSMutableDictionary* conversation = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"(conversations|permanentrooms|groupconversations|adhocrooms):*:entries:*", @"urn", nil];
    NSMutableDictionary* conversation4 = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"(conversations|permanentrooms|groupconversations|adhocrooms):*", @"urn", nil];
    if ([Conversation getConversationEtag] != 0) {
        [conversation setValue:[NSString stringWithFormat:@"%ld", (long)[Conversation getConversationEtag]] forKey:@"ETag"];
        [conversation4 setValue:[NSString stringWithFormat:@"%ld", (long)[Conversation getConversationEtag]] forKey:@"ETag"];
    }
    NSMutableDictionary* voicemail = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"voicemails:*", @"urn", nil];
    if ([Voicemail getVoicemailEtag] != 0) {
        [voicemail setValue:[NSString stringWithFormat:@"%ld", (long)[Voicemail getVoicemailEtag]] forKey:@"ETag"];
    }
    
    NSArray *subscriptionArray = [NSArray arrayWithObjects:voicemail, conversation, conversation4, presence, calls, nil];
    
    __block int count = 1;
    for (NSDictionary *subscription in subscriptionArray) {
        
        [[JCOsgiClient sharedClient] SubscribeToSocketEventsWithAuthToken:self.sessionToken subscriptions:subscription success:^(id JSON) {
            NSLog(@"Subscribing to Socket Events : Success");
            count ++;
            if (count == subscriptionArray.count) {
                [_subscriptionTimer invalidate];
            }
            _subscriptionCount = count;
        } failure:^(NSError *err) {
            NSLog(@"Subscribing to Socket Events : Failed");
            NSLog(@"%@", err);
        }];
    }
}

- (void)initSession
{
    // We have to make sure that the socket is in a initializable state.
    if (_webSocket == nil || _webSocket.readyState == SR_CLOSING || _webSocket.readyState == SR_CLOSED) {
        NSLog(@"Starting Socket");
        _webSocket = [[SRWebSocket alloc] initWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.ws]]];
        _webSocket.delegate = self;
        [_webSocket open];
    }
}

- (void)closeSocket
{
    NSLog(@"Did pull before closing the socket");    
    [_webSocket send:self.json_poll];
    if ([_subscriptionTimer isValid]) {
        [_subscriptionTimer invalidate];
    }
    
    didSignalToCloseSocket = YES;
    [_webSocket close];
}

- (void)reconnect
{
    if (startedInBackground || [[UIApplication sharedApplication] applicationState] == UIApplicationStateActive) {
        [self requestSession];
    }
}

#pragma mark - Websocket Delegates
- (void)webSocketDidOpen:(SRWebSocket *)webSocket
{
    NSLog(@"Socket Did Open");
    
    // Socket connected, send start command
    [_webSocket send:self.json_start];
    
    [self subscribeSession];
}


/**
 *  WebSocket Delegate, Receive events/messages from socket.
 *
 *  @param webSocket SRWebSocket
 *  @param message   NSString
 */
- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message{
    
    NSLog(@"%@",message);
    
    NSData *data = [message dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *messageDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
    
    // if the commend is 'noMessage', and the app state is in the background, then close the socket
    if (messageDictionary[@"cmd"]) {
        if ([messageDictionary[@"cmd"] isEqualToString:@"noMessage"] && startedInBackground) {
            [self closeSocket];
        }
    }
    
    // send message for processing
    [self messageDispatcher:messageDictionary];
    
    // As soon as we're done processing the last received item, poll.
    [_webSocket send:self.json_poll];
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error
{
    
    NSLog(@"%@", [NSString stringWithFormat:@"Connection Failed: %@", [error description]]);
    // If connection fails, try to reconnect.
    [self reconnect];
}


- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean
{
    reason = reason == nil? @"" : reason;
   NSDictionary *userInfo = @{
           @"code": @(code),
           @"reason": reason,
           @"clean": @(wasClean)};
    
    
    //NSLog(@"Connection Closed : %@", userInfo);
    
    
    // If the socket was not closed on purpose (code 200), then try to reconnect
    if (!didSignalToCloseSocket) {
        [self reconnect];
    }
    else {
    // Otherwise invalidere the timer, and if app state is in background, then send completion block.
        [_socketSessionTimer invalidate];
        if (startedInBackground) {
            self.completionBlock(YES, nil);
        }
    }
    
    didSignalToCloseSocket = NO;
}

- (void)cleanup
{
    _cmd_start = nil;
    _cmd_poll = nil;
    _json_start = nil;
    _json_poll = nil;
    _ws = nil;
    _pipedTokens = nil;
    _sessionToken = nil;
}

- (void)messageDispatcher:(NSDictionary*)message
{
    
    NSString *type = [self getMessageType:message];
    NSString *operation = nil;
    if (message[@"data"][@"operation"]) {
        operation = message[@"data"][@"operation"];
    }
    
    NSDictionary *body = [[message objectForKey:@"data"] objectForKey:@"body"];
    
    if ([type isEqualToString:kSocketConversations] || [type isEqualToString:kSocketPermanentRooms]) {
        
        NSString *conversationIdForEntry = [body objectForKey:@"conversation"];
        NSString *conversationId = body[@"id"];
        // Check if we have a conversation for this entry
        NSArray *conversations = [Conversation MR_findByAttribute:@"conversationId" withValue:conversationIdForEntry ? conversationIdForEntry : conversationId];
        
        // if conversationId is nil...it's not a conversationEntry.
        if (conversationIdForEntry) {
            [Conversation saveConversationEtag:[message[@"ETag"] integerValue] managedContext:nil];
            
            // regardless of having a conversation for this entry or not we need to save the entry.
            ConversationEntry *entry = [ConversationEntry addConversationEntry:body sender:nil];
            // increment badge number for conversation ID
            [(JCAppDelegate *)[UIApplication sharedApplication].delegate incrementBadgeCountForConversation:conversationIdForEntry entryId:entry.entryId];
            // notify of new entry
            [[NSNotificationCenter defaultCenter] postNotificationName:conversationIdForEntry object:entry];
            
            //
            if (conversations.count != 0) {
                [[NSNotificationCenter defaultCenter] postNotificationName:kNewConversation object:conversations[0]];
            }
        }
        else {
            // this is probably a new conversation
            conversationId = body[@"id"];
            // if we dont' have, then fetch it
            if (conversations.count == 0) {
                [self RetrieveNewConversation:conversationId];
            }
            else
            {
                Conversation *conversation = [Conversation addConversation:body sender:nil  ];
                [[NSNotificationCenter defaultCenter] postNotificationName:kNewConversation object:conversation];
            }
        }
        
    }
    else if ([type isEqualToString:kSocketPresence])
    {
        Presence * presence = [Presence addPresence:body sender:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:kPresenceChanged object:presence];        
    }
    else if ([type isEqualToString:kSocketVoicemail]) {
        
        NSString *voicemailId = body[@"urn"];
        
        NSArray *voicemails = [Voicemail MR_findByAttribute:@"urn" withValue:voicemailId];
        
        BOOL voicemailHasBeenPreviouslyDeleted = [Voicemail isVoicemailInDeletedList:voicemailId];
        
        Voicemail *voicemail = nil;
        if (!voicemailHasBeenPreviouslyDeleted) {
            [Conversation saveConversationEtag:[message[@"ETag"] integerValue] managedContext:nil];
            voicemail = [Voicemail addVoicemailEntry:body sender:nil];
        }        
        
        //there was no voicemail prior, and now we have one meaning it was successfullt added. Otherwise it was an update.
        if (voicemails.count == 0 && voicemail && [operation isEqualToString:@"posted"]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kNewVoicemail object:voicemail];
            [JSMessageSoundEffect playSMSReceived];
            [(JCAppDelegate *)[UIApplication sharedApplication].delegate incrementBadgeCountForVoicemail:voicemail.voicemailId];
        }
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kSocketEvent" object:message];
}

- (NSString *)getMessageType:(NSDictionary *)message
{
    @try {
        NSDictionary *body = [[message objectForKey:@"data"] objectForKey:@"body"];
        
        NSString *incomingUrn = body[@"urn"];
        NSArray  *explodedUrn = [incomingUrn componentsSeparatedByString:@":"];
        
        NSString *type = explodedUrn[0];
        
        return type;
    }
    @catch (NSException *exception) {
        return nil;
    }
}

- (void)RetrieveNewConversation:(NSString *)conversationId
{
    [[JCOsgiClient sharedClient] RetrieveConversationsByConversationId:conversationId success:^(Conversation *conversation) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kNewConversation object:conversation];
    } failure:^(NSError *err) {
        NSLog(@"%@", err);
    }];
}

#pragma mark - NSTimer
- (void)socketSessionTimerElapsed:(NSNotification *)notification
{
    [self reconnect];
}

- (void)startPoolingFromSocketWithCompletion:(CompletionBlock)completed;
{
    _completionBlock = completed;
    @try {
        [self requestSession];
    }
    @catch (NSException *exception) {
        didSignalToCloseSocket = YES;
        [self closeSocket];
    }
}


@end
