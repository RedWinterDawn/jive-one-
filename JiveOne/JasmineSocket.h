//
//  JasmineSocket.h
//  AttedantConsole
//
//  Created by Eduardo Gueiros on 7/1/14.
//  Copyright (c) 2014 Jive. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PocketSocket/PSWebSocket.h>

@interface JasmineSocket : NSObject <PSWebSocketDelegate>

+ (JasmineSocket *)sharedInstance;

typedef void (^CompletionBlock) (BOOL success, NSError *error);
@property (nonatomic, copy) CompletionBlock completionBlock;
@property (nonatomic, strong) PSWebSocket *socket;
@property (nonatomic, strong) NSString *subscriptionUrl;
@property (nonatomic, strong) NSString *webSocketUrl;
@property (nonatomic, strong) NSString *selfUrl;

- (void)initSocket;
- (void)postSubscriptionsToSocketWithId:(NSString *)ident entity:(NSString *)entity type:(NSString *)type;
- (void)startPoolingFromSocketWithCompletion:(CompletionBlock)completed;
- (void) closeSocketWithReason:(NSString *)reason;
- (void)restartSocket;

@end
