//
//  JCJasmineSocket.m
//  JiveOne
//
//  Created by Robert Barclay on 12/24/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCSocket.h"

#import <SocketRocket/SRWebSocket.h>

#import "JCV5ApiClient+Jasmine.h"
#import "JCV5ApiClient+Jedi.h"

#import "JCKeychain.h"
#import "JCSocketLogger.h"

NSString *const kJCSocketConnectedNotification      = @"socketDidOpen";
NSString *const kJCSocketConnectFailedNotification  = @"socketDidFail";
NSString *const kJCSocketReceivedDataNotification   = @"socketReceivedData";

NSString *const kJCSocketNotificationErrorKey       = @"error";
NSString *const kJCSocketNotificationDataKey        = @"data";
NSString *const kJCSocketNotificationResultKey      = @"result";

NSString *const kJCSocketSessionKeychainKey         = @"socket-session";

NSString *const kJCV5ClientSocketSessionCheckVersionPath                = @"v2";

NSString *const kJCV5ClientSocketSessionResponseWebSocketRequestKey     = @"ws";
NSString *const kJCV5ClientSocketSessionResponseSubscriptionRequestKey  = @"subscriptions";
NSString *const kJCV5ClientSocketSessionResponseSelfRequestKey          = @"self";
NSString *const kJCV5ClientSocketSessionResponseSessionKey              = @"session";
NSString *const kJCV5ClientSocketSessionDeviceTokenKey                  = @"deviceToken";

NSString *const kJCSocketSessionIdKey           = @"sessionId";
NSString *const kJCSocketDeviceTokenKey         = @"deviceToken";
NSString *const kJCSocketJediIdentifierKey      = @"jediID";

NSString *const kJCSocketJediIdKey = @"id";

#define SOCKET_MAX_RETRIES 3

@interface JCSocketSessionInfo : NSObject
{
    NSMutableDictionary *_data;
}

-(instancetype)initWithDataDictionary:(NSDictionary *)data;
-(instancetype)initWithDataDictionary:(NSDictionary *)data deviceToken:(NSString *)deviceToken;

@property(nonatomic, readonly) NSDictionary *data;

@property (nonatomic, readonly) NSString *sessionId;
@property (nonatomic, readonly) NSString *sessionDeviceToken;
@property (nonatomic, readonly) NSURL *subscriptionUrl;
@property (nonatomic, readonly) NSURL *selfUrl;
@property (nonatomic, readonly) NSURL *sessionUrl;

@end

@interface JCSocket () <SRWebSocketDelegate>
{
    SRWebSocket *_socket;
    CompletionHandler _completion;
    BOOL _closeSocketOnPurpose;
    NSInteger _reconnectRetries;
}

@property (nonatomic, strong) NSString *jediIdentifier;
@property (nonatomic, strong) NSString *deviceToken;
@property (nonatomic, strong) JCSocketSessionInfo *sessionInfo;

@end

@implementation JCSocket

- (void)connectWithCompletion:(CompletionHandler)completion
{
    [self connectWithDeviceToken:self.deviceToken completion:completion];
}

- (void)connectWithDeviceToken:(NSString *)deviceToken completion:(CompletionHandler)completion
{
    // If the device token is different from the device token that we have stored for the session
    // url, nuke it. We need to update Jedi, to tell it the new device token. This will delete the
    // session data url and will create a new session.
    
    JCSocketSessionInfo *sessionInfo = self.sessionInfo;
    NSString *currentDeviceToken = sessionInfo.sessionDeviceToken;
    if (currentDeviceToken && ![currentDeviceToken isEqualToString:deviceToken]) {
        [self updateJediWithNewDeviceToken:deviceToken oldDeviceToken:deviceToken completion:completion];
        return;
    }
    
    // Check to see if the session url that is stored is the right API version. If it is not, Nuke it.
    NSURL *sessionUrl = sessionInfo.sessionUrl;
    if (sessionUrl && [sessionUrl.absoluteString rangeOfString:kJCV5ClientSocketSessionCheckVersionPath].location == NSNotFound) {
        [self clearSessionInfo];
        sessionInfo = nil;
    }
    
    // If we have a session url, open a session with the saved session info.
    sessionUrl = sessionInfo.sessionUrl;
    if (sessionUrl) {
        [self openSession:sessionUrl completion:completion];
        return;
    }
    
    // If we do not have a session url,
    [self requestPrioritySessionWithDeviceToken:deviceToken completion:^(BOOL success, JCSocketSessionInfo *newSessionInfo, NSError *error) {
        if (success) {
            self.sessionInfo = newSessionInfo;
            [self openSession:newSessionInfo.sessionUrl completion:completion];
        }
        else {
            if (completion) {
                completion(success, error);
            }
        }
    }];
}

- (void)subscribeToSocketEventsWithArray:(NSArray *) requestArray
{
    NSURL *url = self.sessionInfo.subscriptionUrl;
    if (!url) {
        return;
    }
    
    JCV5ApiClient *apiClient = [JCV5ApiClient sharedClient];
    apiClient.manager.requestSerializer = [JCBearerAuthenticationJSONRequestSerializer new];
    [apiClient.manager POST:url.absoluteString
                 parameters:requestArray
                    success:^(AFHTTPRequestOperation *operation, id responseObject) {
                        NSLog(@"Success");
                    }
                    failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                        NSLog(@"Error Subscribing %@", error);
                    }];
}

- (void)unsubscribeToSocketEvents:(CompletionHandler)completion {
    
    NSURL *url = self.sessionInfo.subscriptionUrl;
    if (!url) {
        return;
    }
    
    if (!url) {
        if (completion) {
            completion(NO, [NSError errorWithDomain:@"Socket" code:0 userInfo:nil]);
        }
        return;
    }
    
    JCV5ApiClient *apiClient = [JCV5ApiClient sharedClient];
    apiClient.manager.requestSerializer = [JCBearerAuthenticationJSONRequestSerializer new];
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
        [self openSession:self.sessionInfo.sessionUrl completion:_completion];
    }
}

#pragma mark - Setters -

-(void)setJediIdentifier:(NSString *)jediIdentifier
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setValue:jediIdentifier forKey:kJCSocketJediIdentifierKey];
    [userDefaults synchronize];
}

-(void)setDeviceToken:(NSString *)deviceToken
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setValue:deviceToken forKey:kJCSocketDeviceTokenKey];
    [userDefaults synchronize];
}

-(void)setSessionInfo:(JCSocketSessionInfo *)sessionInfo
{
    [JCKeychain saveValue:sessionInfo.data forKey:kJCSocketSessionKeychainKey];      // set the keychain value to hold the new session info data.
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

-(NSString *)jediIdentifier
{
    return [[NSUserDefaults standardUserDefaults] valueForKey:kJCSocketJediIdentifierKey];
}

-(NSString *)deviceToken
{
    return [[NSUserDefaults standardUserDefaults] valueForKey:kJCSocketDeviceTokenKey];
}

-(JCSocketSessionInfo *)sessionInfo
{
    NSDictionary *data = [JCKeychain loadValueForKey:kJCSocketSessionKeychainKey];
    return [[JCSocketSessionInfo alloc] initWithDataDictionary:data];
}


#pragma mark - Private -

- (void)updateJediWithNewDeviceToken:(NSString *)deviceToken oldDeviceToken:(NSString *)oldDeviceToken completion:(CompletionHandler)completion
{
    // Nuke stored data. It is now invalid.
    [self clearSessionInfo];
    
    // if for whatever reason we were connected, close the socket.
    [self disconnect];
    
    // Notify Jedi of the changed token.
    [JCV5ApiClient updateJediFromOldDeviceToken:oldDeviceToken
                               toNewDeviceToken:deviceToken
                                     completion:^(BOOL success, id response, NSError *error) {
                                         if (success) {
                                             [self connectWithDeviceToken:deviceToken completion:completion];
                                         } else {
                                             if (completion) {
                                                 completion(NO, error);
                                             }
                                         }
                                     }];
}

/**
 * Requests a Priority session. Checks to see if we have a jedi id stored in the user defaults. If
 * we do, we go ahead a requests a priority session. If we do not have the jedi id, we need to 
 * request it. After processing and storeing the response, we request the priority session.
 */
- (void)requestPrioritySessionWithDeviceToken:(NSString *)deviceToken completion:(void(^)(BOOL success, JCSocketSessionInfo *sessionInfo, NSError *error))completion
{
    // Check to see if we have a stored Jedi ID. If we do, request a priority session from Jasmine.
    NSString *jediId = self.jediIdentifier;
    if (jediId) {
        [self requestPrioritySessionWithJediId:jediId deviceToken:deviceToken completion:completion];
        return;
    }
    
    // If we do not have a jedi id, we request Jedi for an id, passing the device token.
    [JCV5ApiClient requestJediIdForDeviceToken:deviceToken completion:^(BOOL success, id response, NSError *error) {
        if (![response isKindOfClass:[NSDictionary class]]) {
            if (completion) {
                completion(NO, nil, [JCApiClientError errorWithCode:API_CLIENT_RESPONSE_ERROR]);
            }
            return;
        }
        
        // Process response and store.
        NSString *jediId = [((NSDictionary *)response) stringValueForKey:kJCSocketJediIdKey];
        if (!jediId) {
            if (completion) {
                completion(NO, nil, [JCApiClientError errorWithCode:API_CLIENT_RESPONSE_ERROR]);
            }
            return;
        }
        
        self.jediIdentifier = jediId;
        [self requestPrioritySessionWithJediId:jediId deviceToken:deviceToken completion:completion];
    }];
}

- (void)requestPrioritySessionWithJediId:(NSString *)jediId deviceToken:(NSString *)deviceToken completion:(void(^)(BOOL success, JCSocketSessionInfo *sessionInfo, NSError *error))completion
{
    [JCV5ApiClient requestPrioritySessionForJediId:jediId
                                        completion:^(BOOL success, id response, NSError *error) {
                                            if (success) {
                                                JCSocketSessionInfo *sessionInfo = [self processPrioritySessionResponse:response deviceToken:deviceToken];
                                                if(sessionInfo) {
                                                    if (completion) {
                                                        completion(YES, sessionInfo, nil);
                                                    }
                                                } else {
                                                    if (completion) {
                                                        completion(NO, nil, [JCApiClientError errorWithCode:API_CLIENT_RESPONSE_ERROR]);
                                                    }
                                                }
                                            } else {
                                                if (completion) {
                                                    completion(success, nil, error);
                                                }
                                            }
                                        }];
}

- (JCSocketSessionInfo *)processPrioritySessionResponse:(id)response deviceToken:(NSString *)deviceToken
{
    if (![response isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    return [[JCSocketSessionInfo alloc] initWithDataDictionary:(NSDictionary *)response deviceToken:deviceToken];
}

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

-(void)clearSessionInfo
{
    [JCKeychain deleteValueForKey:kJCSocketSessionKeychainKey];
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
        if (code == 1001) {
            NSString *deviceToken = self.deviceToken;
            [self clearSessionInfo];
            [self connectWithDeviceToken:deviceToken completion:^(BOOL success, NSError *error) {
                [self restartSocket];
            }];
        } else {
            [self restartSocket];
        }
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

+ (void)setDeviceToken:(NSString *)deviceToken
{
    [JCSocket sharedSocket].deviceToken = deviceToken;
}

+ (id)copyWithZone:(NSZone *)zone {
    return self;
}

+ (void)restart
{
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

+ (void)reset
{
    JCSocket *socket = [JCSocket sharedSocket];
    [socket disconnect];
    
    // Purge data.
    socket.jediIdentifier = nil;
    [socket clearSessionInfo];
}

+ (void)subscribeToSocketEventsWithArray:(NSArray *) requestArray
{
    [[JCSocket sharedSocket] subscribeToSocketEventsWithArray:requestArray];
}

+ (void)unsubscribeToSocketEvents:(CompletionHandler)completion {
    
    [[JCSocket sharedSocket] unsubscribeToSocketEvents:completion];
}

@end

@implementation JCSocketSessionInfo

-(instancetype)initWithDataDictionary:(NSDictionary *)data
{
    self = [super init];
    if (self) {
        _data = [data mutableCopy];
    }
    return self;
}

-(instancetype)initWithDataDictionary:(NSDictionary *)data  deviceToken:(NSString *)deviceToken
{
    self = [super init];
    if (self) {
        _data = [data mutableCopy];
        [_data setValue:deviceToken forKey:kJCV5ClientSocketSessionDeviceTokenKey];
    }
    return self;
}

-(NSString *)sessionDeviceToken
{
    return [_data stringValueForKey:kJCV5ClientSocketSessionDeviceTokenKey];
}

-(NSString *)sessionId
{
    return [_data objectForKey:kJCSocketSessionIdKey];
}

-(NSURL *)sessionUrl
{
    return [_data urlValueForKey:kJCV5ClientSocketSessionResponseWebSocketRequestKey];
}

-(NSURL *)subscriptionUrl
{
    return [_data urlValueForKey:kJCV5ClientSocketSessionResponseSubscriptionRequestKey];
}

-(NSURL *)selfUrl
{
    return [_data urlValueForKey:kJCV5ClientSocketSessionResponseSelfRequestKey];
}


@end