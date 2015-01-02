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
#import "JCKeychain.h"

NSString *const kJCSocketConnectedNotification      = @"socketDidOpen";
NSString *const kJCSocketConnectFailedNotification  = @"socketDidFail";
NSString *const kJCSocketReceivedDataNotification   = @"socketReceivedData";

NSString *const kJCSocketNotificationErrorKey       = @"error";
NSString *const kJCSocketNotificationDataKey        = @"data";
NSString *const kJCSocketNotificationResultKey      = @"result";

NSString *const kJCSocketSessionKeychainKey         = @"socket-session";

NSString *const kJCV5ClientSocketSessionRequestURL                      = @"https://realtime.jive.com/session";
NSString *const kJCV5ClientSocketSessionResponseWebSocketRequestKey     = @"ws";
NSString *const kJCV5ClientSocketSessionResponseSubscriptionRequestKey  = @"subscriptions";
NSString *const kJCV5ClientSocketSessionResponseSelfRequestKey          = @"self";
NSString *const kJCV5ClientSocketSessionResponseSessionKey              = @"session";
NSString *const kJCV5ClientSocketSessionDeviceTokenKey                  = @"deviceToken";

NSString *const kJCSocketSessionIdKey           = @"sessionId";
NSString *const kJCSocketSessionDeviceTokenKey  = @"deviceToken";



#define SOCKET_MAX_RETRIES 3

@interface JCSocket () <SRWebSocketDelegate>
{
    SRWebSocket *_socket;
    CompletionHandler _completion;
    
    BOOL _closedSocketOnPurpose;
    NSInteger _reconnectRetries;
}

@property (nonatomic, readonly) NSString *sessionId;
@property (nonatomic, readonly) NSString *sessionDeviceToken;
@property (nonatomic, readonly) NSURL *subscriptionUrl;
@property (nonatomic, readonly) NSURL *selfUrl;
@property (nonatomic, readonly) NSURL *sessionUrl;

@end

@implementation JCSocket

- (void)openSession:(NSURL *)sessionUrl completion:(CompletionHandler)completion
{
    // if we have a socket, we have likely already connected.
    if (_socket) {
        [self disconnect];
    }
    
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
    // TODO: Unsubscribe to all socket events.
    [JCSocket unsubscribeToSocketEvents];
    
    [self closeSocketWithReason:@"Disconnecting"];
    _socket = nil;
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

-(NSString *)sessionDeviceToken
{
    NSDictionary *socketSession = [JCKeychain loadValueForKey:kJCSocketSessionKeychainKey];
    if (socketSession) {
        return [socketSession objectForKey:kJCV5ClientSocketSessionDeviceTokenKey];
    }
    return nil;
}

-(NSString *)sessionId
{
    NSDictionary *socketSession = [JCKeychain loadValueForKey:kJCSocketSessionKeychainKey];
    if (socketSession) {
        return [socketSession objectForKey:kJCSocketSessionIdKey];
    }
    return nil;
}

-(NSURL *)sessionUrl
{
    NSDictionary *socketSession = [JCKeychain loadValueForKey:kJCSocketSessionKeychainKey];
    if (socketSession) {
        return [socketSession objectForKey:kJCV5ClientSocketSessionResponseWebSocketRequestKey];
    }
    return nil;
}

-(NSURL *)subscriptionUrl
{
    NSDictionary *socketSession = [JCKeychain loadValueForKey:kJCSocketSessionKeychainKey];
    if (socketSession) {
        return [socketSession objectForKey:kJCV5ClientSocketSessionResponseSubscriptionRequestKey];
    }
    return nil;
}

-(NSURL *)selfUrl
{
    NSDictionary *socketSession = [JCKeychain loadValueForKey:kJCSocketSessionKeychainKey];
    if (socketSession) {
        return [socketSession objectForKey:kJCV5ClientSocketSessionResponseSelfRequestKey];
    }
    return nil;
}

#pragma mark - Private -

- (void)restartSocket
{
    if (_socket && _socket.readyState == SR_CONNECTING) {
        [_socket open];
    }
    else {
        [self openSession:self.sessionUrl completion:NULL];
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
        _completion = NULL;
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
    [JCKeychain deleteValueForKey:kJCSocketSessionKeychainKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:kJCSocketConnectFailedNotification
                                                        object:self
                                                      userInfo:@{kJCSocketNotificationErrorKey:error}];
    if (_completion) {
        _completion(NO, error);
        _completion = NULL;
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message
{
    NSData *data = [message dataUsingEncoding:NSUTF8StringEncoding];
    __autoreleasing NSError *error;
    NSDictionary *result = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&error];
    
    NSDictionary *userInfo;
    if (error) {
        userInfo = @{kJCSocketNotificationDataKey:data,
                     kJCSocketNotificationErrorKey: error};
    }
    else {
        userInfo = @{kJCSocketNotificationDataKey:data,
                     kJCSocketNotificationResultKey:result};
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kJCSocketReceivedDataNotification
                                                        object:self
                                                      userInfo:userInfo];
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    NSLog(@"The websocket closed with code: %@, reason: %@, wasClean: %@", @(code), reason, (wasClean) ? @"YES" : @"NO");
    
    
    /*
     * If we have a completion block, it means
     * this connection was started by the background fetch process or background
     * remote notification. If that's the case then once we're done, we don't want to
     * restart the socket automatically.
     */
    if (_completion) {
        _completion(YES, nil);
        _completion = NULL;
        _closedSocketOnPurpose = YES;
    }
    
    /*
     * If this was not closed on purpose, try to connect again
     */
    if (!_closedSocketOnPurpose) {
        [self restartSocket];
    }
    
    _closedSocketOnPurpose = NO;
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
    // If we have a socket session url, try to reuse it.
    JCSocket *socket = [JCSocket sharedSocket];
    if (socket.sessionUrl) {
        
        // Premtively unsubscribe from all events on the socket.
        [JCSocket unsubscribeToSocketEvents];
        
        NSString *sessionDeviceToken = socket.sessionDeviceToken;
        if (!deviceToken || [sessionDeviceToken isEqualToString:deviceToken]) {
            [socket openSession:socket.sessionUrl completion:completion];
            return;
        }
    }
    
    // If we do not have a session url, we need to request one, creating a session.
    [JCSocket requestSocketSessionRequestUrlsWithDeviceIdentifier:deviceToken completion:^(BOOL success, NSError *error, NSDictionary *userInfo) {
        if (success) {
            
            // Save the session keychain into the keychain for secure access.
            [JCKeychain saveValue:userInfo forKey:kJCSocketSessionKeychainKey];
            
            // Open Session
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

+ (void)reset
{
    [JCSocket disconnect];
    [JCKeychain deleteValueForKey:kJCSocketSessionKeychainKey]; // delete stored keychain credentials.
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
                     if (deviceToken) {
                         [userInfo setObject:deviceToken forKey:kJCSocketSessionDeviceTokenKey];
                     }
                     
                     NSURL *selfUrl = [data urlValueForKey:kJCV5ClientSocketSessionResponseSelfRequestKey];
                     if (selfUrl) {
                         [userInfo setObject:selfUrl forKey:kJCV5ClientSocketSessionResponseSelfRequestKey];
                         [userInfo setObject:selfUrl.lastPathComponent forKey:kJCSocketSessionIdKey];
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

+ (void)unsubscribeToSocketEvents {
    
    NSURL *url = [JCSocket sharedSocket].subscriptionUrl;
    if (!url) {
        return;
    }
    
    JCV5ApiClient *apiClient = [JCV5ApiClient sharedClient];
    [apiClient setRequestAuthHeader:NO];
    [apiClient.manager DELETE:url.absoluteString
                   parameters:nil
                      success:^(AFHTTPRequestOperation *operation, id responseObject) {
                          NSLog(@"Unsubscribe All Events");
                      }
                      failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                          NSLog(@"Error Un subscribing %@", error);
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