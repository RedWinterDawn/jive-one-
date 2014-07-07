//
//  JasmineSocket.m
//  AttedantConsole
//
//  Created by Eduardo Gueiros on 7/1/14.
//  Copyright (c) 2014 Jive. All rights reserved.
//

#import "JasmineSocket.h"
#import "JCContactsClient.h"

@implementation JasmineSocket

+ (JasmineSocket *)sharedInstance
{
    static JasmineSocket* sharedObject = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedObject = [[JasmineSocket alloc] init];
    });
    return sharedObject;
}

- (void)initSocket
{
    if (_socket.readyState != PSWebSocketReadyStateOpen) {
        [self requestSession];
    }
}

- (void) requestSession
{
    [[JCContactsClient sharedClient] RequestSocketSession:^(BOOL suceeded, id responseObject, AFHTTPRequestOperation *operation, NSError *error) {
        if (suceeded) {
            _webSocketUrl = responseObject[@"ws"];
            _subscriptionUrl = responseObject[@"subscriptions"];
            _selfUrl = responseObject[@"self"];
            
            [self startSocketWithURL];
        }
    }];
}

- (void) startSocketWithURL
{
    // create the NSURLRequest that will be sent as the handshake
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:self.webSocketUrl]];
    
    // create the socket and assign delegate
    self.socket = [PSWebSocket clientSocketWithRequest:request];
    self.socket.delegate = self;
    
    // open socket
    [self.socket open];
}

#pragma mark - PSWebSocketDelegate

- (void)webSocketDidOpen:(PSWebSocket *)webSocket {
    NSLog(@"The websocket handshake completed and is now open!");
    [[NSNotificationCenter defaultCenter] postNotificationName:@"socketDidOpen" object:nil];
}
- (void)webSocket:(PSWebSocket *)webSocket didReceiveMessage:(id)message {
    NSLog(@"The websocket received a message: %@", message);
    
    NSData *data = [message dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *messageDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
    
    [self processMessage:messageDictionary];
    
}
- (void)webSocket:(PSWebSocket *)webSocket didFailWithError:(NSError *)error {
    NSLog(@"The websocket handshake/connection failed with an error: %@", error);
}
- (void)webSocket:(PSWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    NSLog(@"The websocket closed with code: %@, reason: %@, wasClean: %@", @(code), reason, (wasClean) ? @"YES" : @"NO");
}

#pragma mark - Subscriptions
- (void)postSubscriptionsToSocketWithId:(NSString *)ident entity:(NSString *)entity type:(NSString *)type
{
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{@"id": ident, @"entity": entity}];
    
    if (type) {
        [params setObject:type forKey:@"type"];
    }
    
    [[JCContactsClient sharedClient] SubscribeToSocketEvents:self.subscriptionUrl dataDictionary:params];
}

- (void) processMessage:(NSDictionary *)message
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"eventForLine" object:message];
}


@end
