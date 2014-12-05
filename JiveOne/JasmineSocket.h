//
//  JasmineSocket.h
//  AttedantConsole
//
//  Created by Eduardo Gueiros on 7/1/14.
//  Copyright (c) 2014 Jive. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SocketRocket/SRWebSocket.h>

@interface JasmineSocket : NSObject <SRWebSocketDelegate>

typedef void (^CompletionBlock) (BOOL success, NSError *error);
@property (nonatomic, copy) CompletionBlock completionBlock;
@property (nonatomic, strong) SRWebSocket *socket;
@property (nonatomic, strong) NSString *subscriptionUrl;
@property (nonatomic, strong) NSString *webSocketUrl;
@property (nonatomic, strong) NSString *selfUrl;

- (void)initSocket;
- (void)postSubscriptionsToSocketWithId:(NSString *)ident entity:(NSString *)entity type:(NSString *)type;
- (void)startPoolingFromSocketWithCompletion:(CompletionBlock)completed;
- (void)closeSocketWithReason:(NSString *)reason;
- (void)restartSocket;

@end


@interface JasmineSocket (Singleton)

+ (JasmineSocket *)sharedInstance;

+ (void)startSocket;
+ (void)stopSocket;

@end