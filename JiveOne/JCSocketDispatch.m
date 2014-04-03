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


@implementation JCSocketDispatch
{
    NSDictionary* cmd_start;
    NSDictionary* cmd_poll;
    NSString *json_start;
    NSString *json_poll;
    NSString* ws;
    NSString* pipedTokens;
    NSString *sessionToken;
}

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
- (void)requestSession
{
    NSLog(@"Requestion Session For Socket");
    [[JCOsgiClient sharedClient] RequestSocketSession:^(id JSON) {
        
        // First, get our current auth token
        KeychainItemWrapper* _keychainWrapper = [[KeychainItemWrapper alloc] initWithIdentifier:kJiveAuthStore accessGroup:nil];
        NSString* authToken = [_keychainWrapper objectForKey:(__bridge id)(kSecAttrAccount)];
        
        // From our response dictionary we'll get some info
        NSDictionary* response = (NSDictionary*)JSON;
        
        // Retrive session token and pipe it together with our auth token
        sessionToken = [NSString stringWithFormat:@"%@",[response objectForKey:@"token"]];
        pipedTokens = [NSString stringWithFormat:@"%@|%@", authToken, sessionToken];
        
        // Create dictionaries that will be converted to JSON objects to be posted to the socket.
        cmd_start = [NSDictionary dictionaryWithObjectsAndKeys:@"start", @"cmd", authToken, @"authToken", sessionToken, @"sessionToken", nil];
        cmd_poll  = [NSDictionary dictionaryWithObjectsAndKeys:@"poll", @"cmd", authToken, @"authToken", sessionToken, @"sessionToken", nil];
        
        NSError* error;
        // json start creation
        NSData* jsonData = [NSJSONSerialization dataWithJSONObject:cmd_start options:NSJSONWritingPrettyPrinted error:&error];
        json_start = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        // json poll creation
        jsonData = [NSJSONSerialization dataWithJSONObject:cmd_poll options:NSJSONWritingPrettyPrinted error:&error];
        json_poll = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        
        
        // Retrieve the ws parameter - this is the endpoint used to connect to our socket.
        ws = [response objectForKey:@"ws"];
        
        NSLog(@"Requestion Session For Socket : Success");
        
        // If we have everyting we need, we can subscribe to events.
        if (ws && sessionToken) {
            [self subscribeSession];
        }
        
    } failure:^(NSError *err) {
        NSLog(@"Requestion Session For Socket : Failed");
        [[NSNotificationCenter defaultCenter] postNotificationName:@"com.jiveone.socketNotConnected" object:nil];
    }];
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
    
    
    NSArray *subscriptionArray = [NSArray arrayWithObjects:conversation, conversation1, conversation2, conversation3, conversation4, presence1, calls, nil];
    
    for (NSDictionary *subscription in subscriptionArray) {
        
        [[JCOsgiClient sharedClient] SubscribeToSocketEventsWithAuthToken:sessionToken subscriptions:subscription success:^(id JSON) {
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
        _webSocket = [[SRWebSocket alloc] initWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:ws]]];
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
    [_webSocket send:json_start];
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message{
    
    NSLog(@"%@",message);
    
    NSString *msgString = message;
    NSData *data = [msgString dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *messageDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
    [self messageDispatcher:messageDictionary];
    
    // As soon as we're done processing the last received item, poll.
    [_webSocket send:json_poll];
    
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
}

- (void)messageDispatcher:(NSDictionary*)message
{
    
    NSString *type = [self getMessageType:message];
    NSDictionary *body = [[message objectForKey:@"data"] objectForKey:@"body"];
    
    if ([type isEqualToString:kSocketConversations] || [type isEqualToString:kSocketPermanentRooms]) {
        NSString *conversationId = [body objectForKey:@"conversation"];
        
        // regardless of having a conversation for this entry or not we need to save the entry.
        [ConversationEntry addConversationEntry:body];
        
        // Check if we have a conversation for this entry
        NSArray *conversation = [Conversation MR_findByAttribute:@"conversationId" withValue:conversationId];
        
        // if we dont' have, then fetch it
        if (conversation.count == 0) {
            [self RetrieveNewConversation:conversationId];
        }
        else {
            [[NSNotificationCenter defaultCenter] postNotificationName:conversationId object:body];
            [[NSNotificationCenter defaultCenter] postNotificationName:kNewConversation object:conversation];
        }
    }
    else if ([type isEqualToString:kSocketPresence])
    {
        Presence * presence = [[JCOsgiClient sharedClient] addPresence:body];
        [[NSNotificationCenter defaultCenter] postNotificationName:kPresenceChanged object:presence];
    }
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




@end
