//
//  JCLineSession.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 10/1/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const kJCLineSessionStateKey;

typedef enum {
    JCNoCall,
    JCInvite,
    JCInviteTrying,
    JCInviteProgress,
    JCInviteFailure,
    JCCallRinging,
    JCCallCanceled,
    JCCallConnected,
    JCCallFailed,
    JCTransferSuccess,
    JCTransferFailed,
    JCCallPutOnHold,
    JCCallPutOffHold
} JCLineSessionState;

@interface JCLineSession : NSObject

@property (nonatomic) long mSessionId;
@property (nonatomic, getter=isHolding) bool hold;
@property (nonatomic) bool mSessionState;
@property (nonatomic) bool mConferenceState;
@property (nonatomic) bool mRecvCallState;
@property (nonatomic) bool mIsReferCall;
@property (nonatomic) long mOriginCallSessionId;
@property (nonatomic) bool mExistEarlyMedia;
@property (nonatomic) bool mVideoState;
@property (nonatomic) JCLineSessionState sessionState;
@property (nonatomic) NSString *callTitle;
@property (nonatomic) NSString *callDetail;

- (BOOL) isReferCall;
- (long) getOriginalCallSessionId;
- (void) setReferCall:(BOOL)referCall originalCallSessionId:(long)originalCallSessionId;
- (void)reset;

@end
