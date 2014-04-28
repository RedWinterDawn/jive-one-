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

@interface JCSocketDispatch()

@property (strong, nonatomic) NSDictionary* cmd_start;
@property (strong, nonatomic) NSDictionary* cmd_poll;
@property (strong, nonatomic) NSString *json_start;
@property (strong, nonatomic) NSString *json_poll;
@property (strong, nonatomic) NSString* ws;
@property (strong, nonatomic) NSString* pipedTokens;
@property (strong, nonatomic) NSString *sessionToken;
@property (strong, nonatomic) NSString *deviceToken;//used for sending a push notification to restore the session if lost
@property (strong, nonatomic) NSTimer *timer;

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




/*
     Request Session Posts information to the API. The returned values are used to stablish a connection to the socket.
 */

- (SRReadyState)socketState
{
    return _webSocket.readyState;
}

- (void)sendPoll
{
    if ([self socketState] == SR_OPEN) {
        [_webSocket send:self.json_poll];
    }
}


- (void)requestSession
{
    NSLog(@"Requestion Session For Socket");
    [self cleanup];
    
    if ([[JCAuthenticationManager sharedInstance] userAuthenticated])  {
        
        [[JCOsgiClient sharedClient] RequestSocketSession:^(id JSON) {
            
            if (_timer) {
                [_timer invalidate];
            }
            
            // First, get our current auth token
            KeychainItemWrapper* _keychainWrapper = [[KeychainItemWrapper alloc] initWithIdentifier:kJiveAuthStore accessGroup:nil];
            NSString* authToken = [_keychainWrapper objectForKey:(__bridge id)(kSecAttrAccount)];
            
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
                [self subscribeSession];
            }
            
        } failure:^(NSError *err) {
            NSLog(@"Requestion Session For Socket : Failed");
            [[NSNotificationCenter defaultCenter] postNotificationName:@"com.jiveone.socketNotConnected" object:nil];
            
            // if we fail to get a session, then try again in 15 seconds
            if (![_timer isValid]) {
                _timer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(elapsedTime:) userInfo:nil repeats:YES];
            }
            
        }];
    }    
}

- (void)subscribeSession
{
    NSLog(@"Subscribing to Socket Events");
    NSDictionary* conversation = [NSDictionary dictionaryWithObjectsAndKeys:@"(conversations|permanentrooms|groupconversations|adhocrooms):*:entries:*", @"urn", nil];
    NSDictionary* conversation1 = [NSDictionary dictionaryWithObjectsAndKeys:@"(conversations|permanentrooms|groupconversations|adhocrooms):*:entries", @"urn", nil];
    NSDictionary* conversation2 = [NSDictionary dictionaryWithObjectsAndKeys:@"meta:(conversations|permanentrooms|groupconversations|adhocrooms):*:entities", @"urn", nil];
    NSDictionary* conversation3 = [NSDictionary dictionaryWithObjectsAndKeys:@"meta:(conversations|permanentrooms|groupconversations|adhocrooms):*:entities:*", @"urn", nil];
    NSDictionary* conversation4 = [NSDictionary dictionaryWithObjectsAndKeys:@"(conversations|permanentrooms|groupconversations|adhocrooms):*", @"urn", nil];
    
    NSDictionary* presence1 = [NSDictionary dictionaryWithObjectsAndKeys:@"presence:entities:*", @"urn", nil];
    
    NSDictionary* calls = [NSDictionary dictionaryWithObjectsAndKeys:@"calls:#", @"urn", nil];

    NSDictionary* voicemail = [NSDictionary dictionaryWithObjectsAndKeys:@"voicemails:*", @"urn", nil];
    
    
    
    NSArray *subscriptionArray = [NSArray arrayWithObjects:voicemail, conversation, conversation1, conversation2, conversation3, conversation4, presence1, calls, nil];
    
    for (NSDictionary *subscription in subscriptionArray) {
        
        [[JCOsgiClient sharedClient] SubscribeToSocketEventsWithAuthToken:self.sessionToken subscriptions:subscription success:^(id JSON) {
            //NSLog(@"%@", JSON);
            NSLog(@"Subscribing to Socket Events : Success");
            
            
        } failure:^(NSError *err) {
            NSLog(@"Subscribing to Socket Events : Failed");
            NSLog(@"%@", err);
        }];
    }
    [self initSession];
}

- (void)initSession
{
    // We have to make sure that the socket is in a initializable state.
    if (_webSocket == nil || _webSocket.readyState == SR_CLOSING || _webSocket.readyState == SR_CLOSED) {
        _webSocket = [[SRWebSocket alloc] initWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.ws]]];
        _webSocket.delegate = self;
        [_webSocket open];
    }
}

- (void)closeSocket
{
    [_webSocket closeWithCode:200 reason:@"App is going on background"];
}

- (void)reconnect
{
    if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive) {
        [self requestSession];
    }
}

#pragma mark - Websocket Delegates
- (void)webSocketDidOpen:(SRWebSocket *)webSocket
{
    // Socket connected, send start command
    [_webSocket send:self.json_start];
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message{
    
    //NSLog(@"%@",message);
    
    NSString *msgString = message;
    NSData *data = [msgString dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *messageDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
    [self messageDispatcher:messageDictionary];
    
    // As soon as we're done processing the last received item, poll.
    [_webSocket send:self.json_poll];
    
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error
{
    //NSLog(@"%@", [NSString stringWithFormat:@"Connection Failed: %@", [error description]]);
    // If connection fails, try to reconnect.
    
    [self reconnect];
}


- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean
{
   NSDictionary *userInfo = @{
           @"code": @(code),
           @"reason": reason,
           @"clean": @(wasClean)};
    
    // If the socket was not closed on purpose (code 200), then try to reconnect
    NSLog(@"Connection Closed : %@", userInfo);
    if (code != 200) {
        [self reconnect];
    }
    else {
        [_timer invalidate];
    }
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
    //NSString *operation = message[@"data"][@"operation"];
    NSDictionary *body = [[message objectForKey:@"data"] objectForKey:@"body"];
    
    if ([type isEqualToString:kSocketConversations] || [type isEqualToString:kSocketPermanentRooms]) {
        
        NSString *conversationIdForEntry = [body objectForKey:@"conversation"];
        NSString *conversationId = body[@"id"];
        // Check if we have a conversation for this entry
        NSArray *conversations = [Conversation MR_findByAttribute:@"conversationId" withValue:conversationIdForEntry ? conversationIdForEntry : conversationId];
        
        // if conversationId is nil...it's not a conversationEntry.
        if (conversationIdForEntry) {
            // regardless of having a conversation for this entry or not we need to save the entry.
            ConversationEntry *entry = [ConversationEntry addConversationEntry:body];
            // increment badge number for conversation ID
            [(JCAppDelegate *)[UIApplication sharedApplication].delegate incrementBadgeCountForConversation:conversationIdForEntry];
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
        }
        
    }
    else if ([type isEqualToString:kSocketPresence])
    {
        Presence * presence = [Presence addPresence:body];
        [[NSNotificationCenter defaultCenter] postNotificationName:kPresenceChanged object:presence];        
    }
    else if ([type isEqualToString:kSocketVoicemail]) {
        
        NSString *voicemailId = body[@"urn"];
        
        NSArray *voicemails = [Voicemail MR_findByAttribute:@"urn" withValue:voicemailId];
        
        BOOL voicemailHasBeenPreviouslyDeleted = [Voicemail isVoicemailInDeletedList:voicemailId];
        
        Voicemail *voicemail = nil;
        if (!voicemailHasBeenPreviouslyDeleted) {
            voicemail = [Voicemail addVoicemailEntry:body];
        }        
        
        //there was no voicemail prior, and now we have one meaning it was successfullt added. Otherwise it was an update.
        if (voicemails.count == 0 && voicemail) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kNewVoicemail object:voicemail];
            [(JCAppDelegate *)[UIApplication sharedApplication].delegate incrementBadgeCountForVoicemail];
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
- (void)elapsedTime:(NSNotification *)notification
{
    [self reconnect];
}


@end
