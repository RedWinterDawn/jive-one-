//
//  JCSocketDispatch.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 2/14/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCSocketDispatch.h"
#import "JCRESTClient.h"
#import "KeychainItemWrapper.h"
#import "ConversationEntry+Custom.h"
#import "Voicemail+Custom.h"
#import "Presence+Custom.h"
#import "JCAppDelegate.h"
#import "JSMessageSoundEffect.h"
#import "LoggerClient.h"
#import "LoggerCommon.h"
@interface JCSocketDispatch()
{
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
@property (nonatomic) BOOL socketIsOpen;

@end

@implementation JCSocketDispatch



+ (instancetype)sharedInstance
{
    LOG_Info();

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
    LogMessage(@"socket", 4, @"sendPoll");
    if (self.webSocket.readyState == SR_OPEN) {
        LogMessage(@"socket", 4, @"Websocket.readyState == SR_OPEN");
        [self.webSocket send:self.json_poll];
    }
}

/**
 *  Fires a request to the server where it retreives a session token used to connect to the websocket
 *  if the user is authenticated.
 *
 */
- (void)requestSession
{
    LOG_Info();
    LogMessage(@"socket", 4, @"Requesting Session For Socket");
    
//    startedInBackground = ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground ||
//                           [UIApplication sharedApplication].applicationState == UIApplicationStateInactive);
    
    [self cleanup];
    
    if ([[JCAuthenticationManager sharedInstance] userAuthenticated] )  {
        LogMessage(@"socket", 4, @"User appears to be authenticated");

        [[JCRESTClient sharedClient] RequestSocketSession:^(id JSON) {
            
            if (_socketSessionTimer) {
                LogMessage(@"socket", 4, @"invalidate socketSessionTimer");

                [_socketSessionTimer invalidate];
            }
            
            // First, get our current auth token
            NSString* authToken = [[JCAuthenticationManager sharedInstance] getAuthenticationToken];
            
            // From our response dictionary we'll get some info
            NSDictionary* response = (NSDictionary*)JSON;
            
            // Retrive session token and pipe it together with our auth token
            self.sessionToken = [NSString stringWithFormat:@"%@",[response objectForKey:@"token"]];
            LogMessage(@"socket", 4, @"Session Token:%@", self.sessionToken);

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
            LogMessage(@"socket", 4, @"Socket Endpoint:%@", self.ws);

            
            // If we have everyting we need, we can subscribe to events.
            if (self.ws && self.sessionToken) {
                LogMessage(@"socket", 4,@"We have an endpoint and a sessionToken");
                [self initSession];
            }
            
        } failure:^(NSError *err) {
            LogMarker(@"Request Session For Socket : Failed");
            
            // if we fail to get a session, then try again in 2 seconds
            if (![_socketSessionTimer isValid]) {
                LogMessage(@"socket", 4, @"Will attempt to create session again in 7 seconds.");

                _socketSessionTimer = [NSTimer scheduledTimerWithTimeInterval:7.0 target:self selector:@selector(socketSessionTimerElapsed:) userInfo:nil repeats:YES];
                [[NSRunLoop currentRunLoop] addTimer:_socketSessionTimer forMode:NSDefaultRunLoopMode];
            }
            
        }];
    }    
}

- (void)timesUpforSubscription
{
    LOG_Info();
    if (self.socketIsOpen) {
        [_subscriptionTimer invalidate];
        [self.webSocket closeWithCode:500 reason:@"Did not subscribe to all events. Retrying"];
    }
}


- (void)subscribeSession
{
    LOG_Info();

    LogMessage(@"socket", 4,@"Subscribing to Socket Sessions");
    int count = 0;
    for (uint8_t sessionType = JCConversationSession; sessionType <= JCCallsSession; sessionType++) {
        [self subscribeToSessionOfType:sessionType];
        count++;
    }
    
    LogMessage(@"socket", 4,@"Subscription Loop: %i", count);
}

-(void)subscribeToSessionOfType:(JCSessionType)sessionType{
    LOG_Info();

    switch (sessionType) {
        case JCConversationSession:{
            NSMutableDictionary* conversation = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"(conversations|permanentrooms|groupconversations|adhocrooms):*:entries:*", @"urn", nil];
                if ([Conversation getConversationEtag] != 0) {
                    [conversation setValue:[NSString stringWithFormat:@"%ld", (long)[Conversation getConversationEtag]] forKey:@"ETag"];
                }
            [self subscribeToSocketUsingDictionary:conversation];
            break;
            }
            
        case JCConversation4Session:{
            NSMutableDictionary* conversation4 = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"(conversations|permanentrooms|groupconversations|adhocrooms):*", @"urn", nil];
                if ([Conversation getConversationEtag] != 0) {
                    [conversation4 setValue:[NSString stringWithFormat:@"%ld", (long)[Conversation getConversationEtag]] forKey:@"ETag"];
                }
            [self subscribeToSocketUsingDictionary:conversation4];
            break;
            }
            
        case JCVoicemailSession:{
            NSMutableDictionary* voicemail = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"voicemails:*", @"urn", nil];
                if ([Voicemail getVoicemailEtag] != 0) {
                    [voicemail setValue:[NSString stringWithFormat:@"%ld", (long)[Voicemail getVoicemailEtag]] forKey:@"ETag"];
                }
            [self subscribeToSocketUsingDictionary:voicemail];
            break;
            }
    
        case JCPresenceSession:{
            NSDictionary* presence = [NSDictionary dictionaryWithObjectsAndKeys:@"presence:entities:*", @"urn", nil];
            [self subscribeToSocketUsingDictionary:presence];
            break;
            }
            
        case JCCallsSession:{
            NSDictionary* calls = [NSDictionary dictionaryWithObjectsAndKeys:@"calls:#", @"urn", nil];
            [self subscribeToSocketUsingDictionary:calls];
            break;
            }
    }
}


- (void)subscribeToSocketUsingDictionary:(NSDictionary*)subscription
{
    LOG_Info();

    NSString* subIdent = [subscription allValues][0];
    LogMessage(@"socket", 4,@"About to subscribe events of type %@", subIdent);
    
    [[JCRESTClient sharedClient] SubscribeToSocketEventsWithAuthToken:self.sessionToken subscriptions:subscription success:^(id JSON) {
        NSString* subscriptionIdentifier = [subscription allValues][0];
        LogMessage(@"socket", 4,@"Subscribing to events of type %@: Succeeded", subscriptionIdentifier);
    } failure:^(NSError *err) {
        NSString* subscriptionIdentifier = [subscription allValues][0];
        LogMessage(@"socket", 4,@"Subscribing to events of type %@: Failed", subscriptionIdentifier);
        LogMessage(@"socket", 4,@"%@", err);
        [self performSelector:@selector(subscribeToSocketUsingDictionary:) withObject:subscription afterDelay:4.0 ];
        LogMessage(@"socket", 4,@"Will attempt subscription for %@ again in 4 seconds", subscriptionIdentifier);
    }];
}

- (void)initSession
{
    LOG_Info();
    LogMessage(@"socket", 4,@"WebSocket status is: %i",self.webSocket.readyState);
    LogMessage(@"socket", 4,@"WebSocket socketIsOpen %i",self.socketIsOpen);

    // We have to make sure that the socket is in a initializable state.
    if (self.webSocket == nil || self.webSocket.readyState == SR_CLOSING || self.webSocket.readyState == SR_CLOSED) {
        if (!self.socketIsOpen) {
            LogMessage(@"socket", 4,@"request");
            self.webSocket = [[SRWebSocket alloc] initWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.ws]]];
            self.webSocket.delegate = self;
            LogMarker(@"Will attempt to open websocket");
            [self.webSocket open];
        }
    }
    else
    {
        LogMessage(@"socket", 4,@"Socket is not in initializable state.");

    }
}

- (void)closeSocket
{
    LOG_Info();
    LogMarker(@"Close Socket Attempt");

    LogMessage(@"socket", 4,@"Did pull before closing the socket");
    [self.webSocket send:self.json_poll];
    if ([_subscriptionTimer isValid]) {
        [_subscriptionTimer invalidate];
    }
    if (self.socketIsOpen) {
        didSignalToCloseSocket = YES;
        [self.webSocket close];
        [self cleanup];
    }
}

- (void)reconnect
{
    LOG_Info();

    // This doesnt make sense to me (@doug) - if the app started in the background or is active ... reconnect???
    // any other state is only transitional to these two options
    //if (self.startedInBackground || [[UIApplication sharedApplication] applicationState] == UIApplicationStateActive) {
        LogMarker(@"Reconnect Attempt");

        [self requestSession];
    //}
}

#pragma mark - Websocket Delegates

- (void)webSocketDidOpen:(SRWebSocket *)webSocket
{
    LOG_Info();
    LogMarker(@"Socket Did Open");
    LogMessage(@"socket", 4,@"WebSocket status should be 1 - it is: %i",self.webSocket.readyState);

    // Socket connected, send start command
    self.socketIsOpen = YES;
    [self.webSocket send:self.json_start];
    
    [self subscribeSession];
}


/**
 *  WebSocket Delegate, Receive events/messages from socket.
 *
 *  @param webSocket SRWebSocket
 *  @param message   NSString
 */
- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message{
    LOG_Info();

    LogMessage(@"socket", 4,@"WebSocket didRecieveMessage: %@",message);
    
    NSData *data = [message dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *messageDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
    
    // if the commend is 'noMessage', and the app state is in the background, then close the socket
    if (messageDictionary[@"cmd"]) {
        if ([messageDictionary[@"cmd"] isEqualToString:@"noMessage"] && self.startedInBackground) {
            [self closeSocket];
        }
    }
    
    //handle Invalid session token message error
    if (messageDictionary[@"message"]) {
        if ([messageDictionary[@"message"] isEqualToString:@"Invalid session token provided"]) {
            LogMarker(@"Invalid session token provided");
            if (self.socketIsOpen) {
                didSignalToCloseSocket = YES;
                LogMessage(@"socket", 4,@"Will close socket");

                [self.webSocket close];
            }
            LogMessage(@"socket", 4,@"Will attempt reconnect");
            [self reconnect];
        }
    }
    
    // send message for processing
    [self messageDispatcher:messageDictionary];
    
    // As soon as we're done processing the last received item, poll.
    [self.webSocket send:self.json_poll];
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error
{
    LOG_Info();
    LogMarker(@"Websocket did Fail.");
    LogMessage(@"socket", 4,@"%@", [NSString stringWithFormat:@"Connection Failed: %@", [error description]]);
    // If connection fails, try to reconnect.
    self.socketIsOpen = NO;
    [self reconnect];
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean
{
    LOG_Info();
    LogMarker(@"WebSocket Did Close");
    self.socketIsOpen = NO;

    reason = reason == nil ? @"" : reason;
   NSDictionary *userInfo = @{
           @"code": @(code),
           @"reason": reason,
           @"clean": @(wasClean)};
    
    
    LogMessage(@"socket", 4,@"Connection Closed : %@", userInfo);
    [self cleanup];
    
    // If the socket was not closed on purpose (code 200), then try to reconnect
    if (!didSignalToCloseSocket) {
        LogMessage(@"socket", 4,@"Trying to reconnect becasue socket was not closed intentionally.");

        [self reconnect];
    }
    else {
    // Otherwise invalidere the timer, and if app state is in background, then send completion block.
        [_socketSessionTimer invalidate];
        if (self.startedInBackground && [UIApplication sharedApplication].applicationState != UIApplicationStateActive) { //add one more check
            if (self.completionBlock) {
                self.completionBlock(YES, nil);
            }
        }
        else {
            [self reconnect];
        }
    }
    
    didSignalToCloseSocket = NO;
}

- (void)cleanup
{
    LOG_Info();
    [_webSocket setDelegate:NULL];
    self.socketIsOpen = NO;
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
    LOG_Info();

    
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
    LOG_Info();

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
    LOG_Info();

    [[JCRESTClient sharedClient] RetrieveConversationsByConversationId:conversationId success:^(Conversation *conversation) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kNewConversation object:conversation];
    } failure:^(NSError *err) {
        LogMessage(@"socket", 4,@"%@", err);
    }];
}

-(BOOL)socketIsOpen
{
    if (!_socketIsOpen) {
        _socketIsOpen = NO;
    }
    return _socketIsOpen;
}


#pragma mark - NSTimer
- (void)socketSessionTimerElapsed:(NSNotification *)notification
{
    LOG_Info();

    LogMessage(@"socket", 4,@"SocketSesstionTimeElapsed: trying to reconnect");
    [self reconnect];
}

- (void)startPoolingFromSocketWithCompletion:(CompletionBlock)completed;
{
    LOG_Info();

    _completionBlock = completed;
    @try {
        [self requestSession];
    }
    @catch (NSException *exception) {
        LogMessage(@"socket", 4,@"Exception Failed to Pool from Socket: %@", exception);

        if (self.socketIsOpen) {
            didSignalToCloseSocket = YES;
            [self closeSocket];
        }
    }
}


@end
