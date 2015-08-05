//
//  JCJasmineSocket.h
//  JiveOne
//
//  Created by Robert Barclay on 12/24/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

@import Foundation;

extern NSString *const kJCSocketConnectedNotification;
extern NSString *const kJCSocketConnectFailedNotification;
extern NSString *const kJCSocketReceivedDataNotification;

extern NSString *const kJCSocketNotificationErrorKey;
extern NSString *const kJCSocketNotificationDataKey;
extern NSString *const kJCSocketNotificationResultKey;

@interface JCSocket : NSObject

@property (nonatomic, readonly) BOOL isReady;
@property (nonatomic, readonly) BOOL isConnecting;

- (void)connectWithCompletion:(CompletionHandler)completion;

// Subscribes the socket session for events related to a jrn identifeir on a entity for event types.
- (void)subscribeToSocketEventsWithArray:(NSArray *) requestArray;

// Unsubscribes from all socket events.
- (void)unsubscribeToSocketEvents:(CompletionHandler)completion;

@end

@interface JCSocket (Singleton)

+ (instancetype)sharedSocket;

+ (void)setDeviceToken:(NSString *)deviceToken;

+ (void)restart;
+ (void)disconnect;
+ (void)reset;

+ (void)subscribeToSocketEventsWithArray:(NSArray *) requestArray;
+ (void)unsubscribeToSocketEvents:(CompletionHandler)completion;

@end