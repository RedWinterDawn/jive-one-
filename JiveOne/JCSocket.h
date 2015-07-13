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

@end

@interface JCSocket (Singleton)

+ (instancetype)sharedSocket;

+ (void)connectWithDeviceToken:(NSString *)deviceToken completion:(CompletionHandler)completion;
+ (void)restart;
+ (void)disconnect;

@end

@interface JCSocket (V5Client)

// Requests from V5 portal urls needed to open a socket session.
+ (void)createPrioritySession:(NSString *)deviceToken :(CompletionHandler)completion;

// Subscribes the socket session for events related to a jrn identifeir on a entity for event types.
+ (void)subscribeToSocketEventsWithArray:(NSArray *) requestArray;

// Unsubscribes from all socket events.
+ (void)unsubscribeToSocketEvents:(CompletionHandler)completion;

@end