//
//  JCJasmineSocket.m
//  JiveOne
//
//  Created by Robert Barclay on 12/24/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCSocket.h"
#import <SocketRocket/SRWebSocket.h>
#import "JCV5ApiClient.h"

NSString *const kJCSocketConnectedNotification      = @"socketDidOpen";
NSString *const kJCSocketConnectFailedNotification  = @"socketDidFail";
NSString *const kJCSocketReceivedDataNotification   = @"socketReceivedData";

NSString *const kJCSocketNotificationErrorKey       = @"error";
NSString *const kJCSocketNotificationDataKey        = @"data";
NSString *const kJCSocketNotificationResultKey      = @"result";

NSString *const kJCV5ClientSocketSessionRequestURL                      = @"https://realtime.jive.com/session";
NSString *const kJCV5ClientSocketSessionResponseWebSocketRequestKey     = @"ws";
NSString *const kJCV5ClientSocketSessionResponseSubscriptionRequestKey  = @"subscriptions";
NSString *const kJCV5ClientSocketSessionResponseSelfRequestKey          = @"self";
NSString *const kJCV5ClientSocketSessionDeviceTokenKey                  = @"deviceToken";


#define SOCKET_MAX_RETRIES 3

@interface JCSocket () <SRWebSocketDelegate>
{
    SRWebSocket *_socket;
    CompletionHandler _completion;
    
    NSURL *_url;
    BOOL _closedSocketOnPurpose;
    NSInteger _reconnectRetries;
}

@property (nonatomic, strong) NSURL *subscriptionUrl;

@end

@implementation JCSocket

- (void)openSession:(NSURL *)sessionUrl completion:(CompletionHandler)completion
{
    // if we have a socket, we have likely already connected.
    if (_socket) {
        [self disconnect];
    }
    
    _url = sessionUrl;
    _completion = completion;
    _socket = [[SRWebSocket alloc] initWithURL:sessionUrl];
    _socket.delegate = self;
    
    // Initiate Open Socket
    if (_socket.readyState == SR_CONNECTING) {
        [_socket open];
    }
}

-(void)disconnect
{
    [self closeSocketWithReason:@"Disconnecting"];
    _socket = nil;
    _url = nil;
}

- (void)start
{
    if (!self.isReady) {
        [_socket open];
    }
}

- (void)stop
{
    [self closeSocketWithReason:@"Entering background"];
}

#pragma mark - Getters -

-(BOOL)isReady
{
    return (_socket && _socket.readyState == SR_OPEN);
}

#pragma mark - Private -

- (void)restartSocket
{
    if (_socket && _socket.readyState == SR_CONNECTING) {
        [_socket open];
    }
    else {
        [self openSession:_url completion:NULL];
    }
}

- (void)closeSocketWithReason:(NSString *)reason
{
    if (_socket) {
        [_socket closeWithCode:1001 reason:reason];
        _closedSocketOnPurpose = YES;
        _socket = nil;
    }
}

- (void)closeSocket
{
    if (_socket) {
        [_socket closeWithCode:0 reason:nil];
        _closedSocketOnPurpose = NO;
        _socket = nil;
    }
}

- (void)reset
{
    _completion = nil;
    _socket = nil;
}

#pragma mark - Delegate Handlers -

#pragma mark SRWebSocketDelegate



- (void)webSocketDidOpen:(SRWebSocket *)webSocket
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kJCSocketConnectedNotification object:self];
    
    if (_completion) {
        _completion(YES, nil);
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error
{
    // If we fail to handshake, retry up to the max retries.
    if (_reconnectRetries < SOCKET_MAX_RETRIES) {
        _reconnectRetries++;
        [self restartSocket];
        return;
    }
    
    // If we fail our retries, fail out, broadcasting failure. We will need to be restarted from
    // outside of ourselves through openSession, so we clear out the data.
    _reconnectRetries = 0;
    _socket = nil;
    _url = nil;
    [[NSNotificationCenter defaultCenter] postNotificationName:kJCSocketConnectFailedNotification
                                                        object:self
                                                      userInfo:@{kJCSocketNotificationErrorKey:error}];
    if (_completion) {
        _completion(NO, error);
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message
{
    NSData *data = [message dataUsingEncoding:NSUTF8StringEncoding];
    __autoreleasing NSError *error;
    NSDictionary *result = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&error];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kJCSocketConnectFailedNotification
                                                        object:self
                                                      userInfo:@{kJCSocketNotificationErrorKey:error,
                                                                 kJCSocketNotificationDataKey:data,
                                                                 kJCSocketNotificationResultKey:result}];
}



- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    NSLog(@"The websocket closed with code: %@, reason: %@, wasClean: %@", @(code), reason, (wasClean) ? @"YES" : @"NO");
    
    
//    /*
//     * If we have a completion block, it means
//     * this connection was started by the background fetch process or background
//     * remote notification. If that's the case then once we're done, we don't want to
//     * restart the socket automatically.
//     */
//    if (self.completionBlock) {
//        self.completionBlock(YES, nil);
//        closedSocketOnPurpose = YES;
//    }
//    
//    
//    /*
//     * If this was not closed on purpose, try to connect again
//     */
//    if (!closedSocketOnPurpose) {
//        [self restartSocket];
//    }
//    
//    closedSocketOnPurpose = NO;
}

@end

@implementation JCSocket (Singleton)

+(instancetype)sharedSocket
{
    static JCSocket *socket = nil;
    static dispatch_once_t socketLoaded;
    dispatch_once(&socketLoaded, ^{
        socket = [[JCSocket alloc] init];
    });
    return socket;
}

+ (id)copyWithZone:(NSZone *)zone
{
    return self;
}

+ (void)connectWithDeviceToken:(NSString *)deviceToken completion:(CompletionHandler)completion
{
    JCSocket *socket = [JCSocket sharedSocket];
    [JCSocket requestSocketSessionRequestUrlsWithDeviceIdentifier:deviceToken completion:^(BOOL success, NSError *error, NSDictionary *userInfo) {
        if (success) {
            socket.subscriptionUrl = [userInfo objectForKey:kJCV5ClientSocketSessionResponseSubscriptionRequestKey];
            [socket openSession:[userInfo objectForKey:kJCV5ClientSocketSessionResponseWebSocketRequestKey] completion:completion];
        }
        else {
            NSLog(@"Failed requesting socket urls: %@", [error description]);
        }
    }];
}

+ (void)disconnect
{
    [[JCSocket sharedSocket] disconnect];
}

+ (void)start
{
    [[JCSocket sharedSocket] start];
}

+ (void)stop
{
    [[JCSocket sharedSocket] stop];
}

@end

@implementation JCSocket (V5Client)

+ (void)requestSocketSessionRequestUrlsWithDeviceIdentifier:(NSString *)deviceToken completion:(ResultCompletionHandler)completed
{
    JCV5ApiClient *client = [JCV5ApiClient sharedClient];
    [client setRequestAuthHeader:NO];
    [client.manager POST:kJCV5ClientSocketSessionRequestURL
              parameters:((deviceToken && deviceToken.length > 0) ? @{kJCV5ClientSocketSessionDeviceTokenKey : deviceToken} : nil)
                 success:^(AFHTTPRequestOperation *operation, id responseObject) {
                     if (![responseObject isKindOfClass:[NSDictionary class]]) {
                         completed(NO, nil, nil);
                         return;
                     }
                     
                     NSDictionary *data = (NSDictionary *)responseObject;
                     NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
                     
                     NSURL *selfUrl = [data urlValueForKey:kJCV5ClientSocketSessionResponseSelfRequestKey];
                     if (selfUrl) {
                         [userInfo setObject:selfUrl forKey:kJCV5ClientSocketSessionResponseSelfRequestKey];
                     }
                     
                     NSURL *websocketUrl = [data urlValueForKey:kJCV5ClientSocketSessionResponseWebSocketRequestKey];
                     if (websocketUrl) {
                         [userInfo setObject:websocketUrl forKey:kJCV5ClientSocketSessionResponseWebSocketRequestKey];
                     }
                     
                     NSURL *subscriptionUrl = [data urlValueForKey:kJCV5ClientSocketSessionResponseSubscriptionRequestKey];
                     if (subscriptionUrl) {
                         [userInfo setObject:subscriptionUrl forKey:kJCV5ClientSocketSessionResponseSubscriptionRequestKey];
                     }
                     
                     completed(YES, nil, userInfo);
                     
                 }
                 failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                     completed(NO, error, nil);
                 }];
}

NSString *const kJCSocketParameterIdentifierKey = @"id";
NSString *const kJCSocketParameterEntityKey     = @"entity";
NSString *const kJCSocketParameterTypeKey       = @"type";

+ (void)subscribeToSocketEventsWithIdentifer:(NSString *)identifer entity:(NSString *)entity type:(NSString *)type
{
    NSDictionary *requestParameters = [self subscriptionDictionaryForIdentifier:identifer entity:entity type:type];
    NSURL *url = [JCSocket sharedSocket].subscriptionUrl;
    JCV5ApiClient *apiClient = [JCV5ApiClient sharedClient];
    [apiClient setRequestAuthHeader:NO];
    [apiClient.manager POST:url.absoluteString
                 parameters:requestParameters
                    success:^(AFHTTPRequestOperation *operation, id responseObject) {
                        NSLog(@"Success");
                    }
                    failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                        NSLog(@"Error Subscribing %@", error);
                    }];
}

+ (NSDictionary *)subscriptionDictionaryForIdentifier:(NSString *)identifier entity:(NSString *)entity type:(NSString *)type
{
    if (!identifier || identifier.length < 1) {
        return nil;
    }
    
    if (!entity || entity.length < 1) {
        return nil;
    }
    
    NSMutableDictionary *parameters = [@{kJCSocketParameterIdentifierKey: identifier,
                                         kJCSocketParameterEntityKey: entity} mutableCopy];
    
    if (type) {
        [parameters setObject:type forKey:kJCSocketParameterTypeKey];
    }
    
    return parameters;
}

@end