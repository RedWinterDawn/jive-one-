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

NSString *const kJCLineSessionStateKey = @"sessionState";

@implementation JCLineSession

#pragma mark - Setters -

- (void) setReferCall:(BOOL)referCall originalCallSessionId:(long)originalCallSessionId
{
    _mIsReferCall = referCall;
    _mOriginCallSessionId = originalCallSessionId;
}

- (void) setHold:(bool)hold
{
    [self willChangeValueForKey:@"hold"];
    _hold = hold;
    if (hold) {
        self.sessionState = JCCallPutOnHold;
    }
    else {
        self.sessionState = JCCallPutOffHold;
    }
    [self didChangeValueForKey:@"hold"];
}

#pragma mark - Getters -

- (BOOL) isReferCall
{
    return _mIsReferCall;
}
- (long) getOriginalCallSessionId
{
    return _mOriginCallSessionId;
}

#pragma mark - Actions -

- (void)reset
{
	[self setMSessionId:INVALID_SESSION_ID];
    
    
    
	[self setMSessionState:false];
	[self setMConferenceState:false];
	[self setMRecvCallState:false];
	[self setMOriginCallSessionId:INVALID_SESSION_ID];
	[self setMIsReferCall:false];
	[self setMExistEarlyMedia:false];
	[self setMVideoState:false];
    
    _hold = false;
    self.sessionState = JCNoCall;
}

@end
