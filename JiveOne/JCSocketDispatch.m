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
#import "ConversationEntry.h"


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

- (void)initSession
{
    _webSocket = [[SRWebSocket alloc] initWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:ws]]];
    _webSocket.delegate = self;
    [_webSocket open];
}

- (void)requestSession
{
    [[JCOsgiClient sharedClient] RequestSocketSession:^(id JSON) {
        KeychainItemWrapper* _keychainWrapper = [[KeychainItemWrapper alloc] initWithIdentifier:kJiveAuthStore accessGroup:nil];
        
        NSDictionary* response = (NSDictionary*)JSON;
        NSLog(@"%@",[response description]);
        
        sessionToken = [NSString stringWithFormat:@"%@",[response objectForKey:@"token"]];
        NSString* authToken = [_keychainWrapper objectForKey:(__bridge id)(kSecAttrAccount)];
        pipedTokens = [NSString stringWithFormat:@"%@%@", authToken, sessionToken];
        
        cmd_start = [NSDictionary dictionaryWithObjectsAndKeys:@"start", @"cmd", authToken, @"authToken", sessionToken, @"sessionToken", nil];
        cmd_poll  = [NSDictionary dictionaryWithObjectsAndKeys:@"poll", @"cmd", authToken, @"authToken", sessionToken, @"sessionToken", nil];
        NSError* error;
        NSData* jsonData = [NSJSONSerialization dataWithJSONObject:cmd_start options:NSJSONWritingPrettyPrinted error:&error];
        
        json_start = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        jsonData = [NSJSONSerialization dataWithJSONObject:cmd_poll options:NSJSONWritingPrettyPrinted error:&error];
        json_poll = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        
        ws = [response objectForKey:@"ws"];
        
        if (ws && sessionToken) {
            [self subscribeSession];
        }
        
    } failure:^(NSError *err) {
        NSLog(@"%@", [err description]);
    }];
}

- (void)subscribeSession
{
    NSDictionary* subscriptions = [NSDictionary dictionaryWithObjectsAndKeys:@"(conversations|permanentrooms|groupconversations|adhocrooms):*:entries:*", @"urn", nil];
    
    [[JCOsgiClient sharedClient] SubscribeToSocketEventsWithAuthToken:sessionToken subscriptions:subscriptions success:^(id JSON) {
        [self initSession];
    } failure:^(NSError *err) {
        NSLog(@"%@", err);
    }];
}

#pragma mark - Websocket Delegates
- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message{
    
    NSLog(@"%@",message);
    
    NSString *msgString = message;
    NSData *data = [msgString dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *messageDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
    [self messageDispatcher:messageDictionary];
    
    [_webSocket send:json_poll];
    
}
- (void)webSocketDidOpen:(SRWebSocket *)webSocket
{
    [_webSocket send:json_start];
}
- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error
{
    NSLog(@"%@", [NSString stringWithFormat:@"Connection Failed: %@", [error description]]);
}
- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean
{
   NSLog(@"Connection Closed");
}

- (void)messageDispatcher:(NSDictionary*)message
{   
    NSDictionary *body = [[message objectForKey:@"data"] objectForKey:@"body"];
    NSString *type = [body objectForKey:@"type"];
    
    if ([type isEqualToString:@"chat"]) {
        NSString *conversationId = [body objectForKey:@"conversation"];
        
        // regardless of having a conversation for this entry or not we need to save the entry.
        [[JCOsgiClient sharedClient] addConversationEntry:body];
        
        // Check if we have a conversation for this entry
        NSArray *conversation = [Conversation MR_findByAttribute:@"conversationId" withValue:conversationId];
        
        // if we dont' have, then fetch it
        if (conversation.count == 0) {
            [[JCOsgiClient sharedClient] RetrieveConversationsByConversationId:conversationId success:^(Conversation *conversation) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"NewConversation" object:conversation];
            } failure:^(NSError *err) {
                NSLog(@"%@", err);
            }];
        }
        else {
            [[NSNotificationCenter defaultCenter] postNotificationName:conversationId object:body];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"NewConversation" object:conversation];
        }
    }
}




@end
