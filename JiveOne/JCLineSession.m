//
//  JCLineSession.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 10/1/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCLineSession.h"

#define LINE_BASE 0
#define MAX_LINES 2
#define INVALID_SESSION_ID -1

@implementation JCLineSession

- (BOOL) isReferCall
{
	return _mIsReferCall;
}
- (long) getOriginalCallSessionId
{
	return _mOriginCallSessionId;
}
- (void) setReferCall:(BOOL)referCall originalCallSessionId:(long)originalCallSessionId
{
	_mIsReferCall = referCall;
	_mOriginCallSessionId = originalCallSessionId;
}
- (void)reset
{
	[self setMSessionId:INVALID_SESSION_ID];
	[self setMHoldSate:false];
	[self setMSessionState:false];
	[self setMConferenceState:false];
	[self setMRecvCallState:false];
	[self setMOriginCallSessionId:INVALID_SESSION_ID];
	[self setMIsReferCall:false];
	[self setMExistEarlyMedia:false];
	[self setMVideoState:false];
	[self setMCallState:JCNoCall];
}

- (void)setMCallState:(JCCall)mCallState
{
	self.mCallState = mCallState;
	if (self.delegate && [self.delegate respondsToSelector:@selector(callStateDidChange:callState:)]) {
		[self.delegate callStateDidChange:self.mSessionId callState:self.mCallState];
	}
}

@end
