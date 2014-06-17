//
//  JCSocketDispatch.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 2/14/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SocketRocket/SRWebSocket.h>

/* The types of sessions we will register for. */
typedef enum : uint8_t {
	JCConversationSession = 0,
	JCConversation4Session,
	JCVoicemailSession,
	JCPresenceSession,
	JCCallsSession
} JCSessionType;

@interface JCSocketDispatch : NSObject <SRWebSocketDelegate>

typedef void (^CompletionBlock) (BOOL success, NSError *error);
@property (nonatomic, strong) SRWebSocket *webSocket;
@property (nonatomic) NSInteger subscriptionCount;
@property (nonatomic, copy) CompletionBlock completionBlock;
@property BOOL startedInBackground;

+ (instancetype)sharedInstance;
- (void)startPoolingFromSocketWithCompletion:(CompletionBlock)completed;
- (void)requestSession;
- (void)closeSocket;
- (void)sendPoll;

@end
