//
//  JCLineSession.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 10/1/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
@class JCLineSession;
@protocol JCLineSessionDelegate <NSObject>

- (void) callStateDidChange:(long)sessionId callState:(JCCall)callState;

@end

@interface JCLineSession : NSObject

@property (nonatomic, weak) id<JCLineSessionDelegate> delegate;
@property (nonatomic) long mSessionId;
@property (nonatomic) bool mHoldSate;
@property (nonatomic) bool mSessionState;
@property (nonatomic) bool mConferenceState;
@property (nonatomic) bool mRecvCallState;
@property (nonatomic) bool mIsReferCall;
@property (nonatomic) long mOriginCallSessionId;
@property (nonatomic) bool mExistEarlyMedia;
@property (nonatomic) bool mVideoState;
@property (nonatomic) JCCall mCallState;
@property (nonatomic) NSString *callTitle;
@property (nonatomic) NSString *callDetail;

- (BOOL) isReferCall;
- (long) getOriginalCallSessionId;
- (void) setReferCall:(BOOL)referCall originalCallSessionId:(long)originalCallSessionId;
- (void)reset;

@end
