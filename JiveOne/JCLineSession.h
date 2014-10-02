//
//  JCLineSession.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 10/1/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JCLineSession : NSObject

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

- (BOOL) isReferCall;
- (long) getOriginalCallSessionId;
- (void) setReferCall:(BOOL)referCall originalCallSessionId:(long)originalCallSessionId;
- (void)reset;

@end
