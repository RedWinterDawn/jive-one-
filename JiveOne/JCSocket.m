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
#import "JCSocketLogger.h"

NSString *const kJCSocketConnectedNotification      = @"socketDidOpen";
NSString *const kJCSocketConnectFailedNotification  = @"socketDidFail";
NSString *const kJCSocketReceivedDataNotification   = @"socketReceivedData";

NSString *const kJCSocketNotificationErrorKey       = @"error";
NSString *const kJCSocketNotificationDataKey        = @"data";
NSString *const kJCSocketNotificationResultKey      = @"result";

NSString *const kJCSocketSessionKeychainKey         = @"socket-session";

NSString *const kJCV5ClientSocketSessionRequestURL                      = @"https://realtime.jive.com/v2/session/priority/jediId/451";      //  we need priority sessions so we can get push notifications
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
    BOOL _closeSocketOnPurpose;
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
    if (_socket && ![_socket.url isEqual:sessionUrl]) {
        [self disconnect];
    }
    
    if (self.isReady || self.isConnecting) {
        return;
    }
    
    
    _completion = completion;
    _socket = [[SRWebSocket alloc] initWithURL:sessionUrl];
    _socket.delegate = self;
    if (_socket.readyState == SR_CONNECTING) {
        [JCSocketLogger logSocketEvent:[NSString stringWithFormat:@"Opening Session: %@", sessionUrl.absoluteString]];
        [_socket open];
    }
}

-(void)disconnect
{
    if (self.isReady) {
        [self closeSocketWithReason:@"Disconnecting"];
    }
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

- (void)restartSocket
{
    [JCSocketLogger logSocketEvent:@"Restarting Socket"];
    if (_socket && _socket.readyState == SR_CONNECTING) {
        [_socket open];
    }
    else {
        [self openSession:self.sessionUrl completion:_completion];
    }
}

#pragma mark - Getters -

-(BOOL)isReady
{
    return (_socket && _socket.readyState == SR_OPEN);
}

-(BOOL)isConnecting
{
    return (_socket && _socket.readyState == SR_CONNECTING);
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

- (void)closeSocketWithReason:(NSString *)reason
{
    _closeSocketOnPurpose = YES;
    if (_socket) {
        [JCSocketLogger logSocketEvent:[NSString stringWithFormat:@"Closing Socket Session: %@", reason]];
        [_socket closeWithCode:1001 reason:reason];
        _socket = nil;
    }
}

- (void)closeSocket
{
    _closeSocketOnPurpose = YES;
    if (_socket) {
        [JCSocketLogger logSocketEvent:[NSString stringWithFormat:@"Closing Socket Session"]];
        [_socket closeWithCode:0 reason:nil];
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
    [JCSocketLogger logSocketEvent:@"Socket connected"];
    [[NSNotificationCenter defaultCenter] postNotificationName:kJCSocketConnectedNotification object:self];
    
    if (_completion) {
        _completion(YES, nil);
        _completion = NULL;
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error
{
    [JCSocketLogger logSocketEvent:[NSString stringWithFormat:@"Socket failed to connect:"]];
    
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
    [JCSocketLogger logSocketEvent:[NSString stringWithFormat:@"The websocket closed with code: %@, reason: %@, wasClean: %@", @(code), reason, (wasClean) ? @"YES" : @"NO"]];
    
    /*
     * If we have a completion block, it means
     * this connection was started by the background fetch process or background
     * remote notification. If that's the case then once we're done, we don't want to
     * restart the socket automatically.
     */
    if (_completion) {
        _completion(YES, nil);
        _completion = NULL;
    }
    
    /*
     * If this was not closed on purpose, try to connect again
     */
    if (!_closeSocketOnPurpose) {
        [self restartSocket];
    }
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
//start the socket?
+ (void)connectWithDeviceToken:(NSString *)deviceToken completion:(CompletionHandler)completion
{
    // If we have a socket session url, try to reuse it.
    JCSocket *socket = [JCSocket sharedSocket];
    
    // If the device token is different from the device token that we have stored for the session
    // url, nuke it. This will delete the session url and will create a new session.
    if (![socket.sessionDeviceToken isEqualToString:deviceToken]) {
        [JCKeychain deleteValueForKey:kJCSocketSessionKeychainKey]; // delete stored keychain credentials.
        [socket disconnect];
    }
    
    // If this is the first time we are connecting, or we have reset the session keychain, request it.
    if (!socket.sessionUrl) {
        [JCSocket createPrioritySession:deviceToken :completion];
        return;
    }
    
    // If we are still here, open session. We have all the data we need.
    [socket openSession:socket.sessionUrl completion:completion];
}

+ (void)restart {
    JCSocket *socket = [JCSocket sharedSocket];
    if (socket.isReady) {
        return;
    }
    
    [socket start];
}

+ (void)disconnect
{
    [[JCSocket sharedSocket] disconnect];
}

@end

@implementation JCSocket (V5Client)

+ (void)createPrioritySession:(NSString *)deviceToken :(CompletionHandler)completion
{
    JCV5ApiClient *client = [JCV5ApiClient new];
    [client.manager POST:kJCV5ClientSocketSessionRequestURL
              parameters:((deviceToken && deviceToken.length > 0) ? @{kJCV5ClientSocketSessionDeviceTokenKey : deviceToken} : nil)
                 success:^(AFHTTPRequestOperation *operation, id responseObject) {
                     if (![responseObject isKindOfClass:[NSDictionary class]]) {
                         if (completion) {
                             completion(NO, nil);
                         }
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
                     
                     // Save the session keychain into the keychain for secure access.
                     [JCKeychain saveValue:userInfo forKey:kJCSocketSessionKeychainKey];
                     
                     // Open Session
                     [[JCSocket sharedSocket] openSession:websocketUrl completion:completion];
                 }
                 failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                     if (completion) {
                         completion(NO, error);
                     }
                 }];
}


+ (void)subscribeToSocketEventsWithArray:(NSArray *) requestArray
{
    
    NSLog(@"Here is your request params:::::  \n\n\n %@", requestArray);
    NSURL *url = [JCSocket sharedSocket].subscriptionUrl;
    JCV5ApiClient *apiClient = [JCV5ApiClient sharedClient];
    [apiClient.manager POST:url.absoluteString
                 parameters:requestArray
                    success:^(AFHTTPRequestOperation *operation, id responseObject) {
                        NSLog(@"Success");
                    }
                    failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                        NSLog(@"Error Subscribing %@", error);
                    }];
}

+ (void)unsubscribeToSocketEvents:(CompletionHandler)completion {
    
    NSURL *url = [JCSocket sharedSocket].subscriptionUrl;
    if (!url) {
        if (completion) {
            completion(NO, [NSError errorWithDomain:@"Socket" code:0 userInfo:nil]);
        }
        return;
    }
    
    JCV5ApiClient *apiClient = [JCV5ApiClient sharedClient];
    [apiClient.manager DELETE:url.absoluteString
                   parameters:nil
                      success:^(AFHTTPRequestOperation *operation, id responseObject) {
                          NSLog(@"Unsubscribe All Events");
                          if (completion) {
                              completion(YES, nil);
                          }
                          
                      }
                      failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                          if (completion) {
                              completion(NO, error);
                          }
                      }];
}

@end