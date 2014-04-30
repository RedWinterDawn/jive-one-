//
//  JCSocketDispatch.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 2/14/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SocketRocket/SRWebSocket.h>



@interface JCSocketDispatch : NSObject <SRWebSocketDelegate>

typedef void (^CompletionBlock) (BOOL success, NSError *error);

@property (nonatomic, strong) SRWebSocket *webSocket;
@property (nonatomic, strong) NSMutableDictionary *badges;
@property (nonatomic, copy) CompletionBlock completionBlock;


- (void)startPoolingFromSocketWithCompletion:(CompletionBlock)completed;

+ (instancetype)sharedInstance;

- (void)requestSession:(BOOL)inBackground;
- (void)closeSocket;

- (SRReadyState)socketState;

- (void)sendPoll;

@end
