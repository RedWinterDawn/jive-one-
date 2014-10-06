//
//  JCCall.m
//  JiveOne
//
//  Created by Robert Barclay on 10/2/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCCallCard.h"
#import "JCCallCardManager.h"

@interface JCCallCard ()
{
    bool _hold;
}

@end


@implementation JCCallCard


-(void)setHold:(BOOL)hold
{
    
    [self willChangeValueForKey:@"hold"];
    
    [[JCCallCardManager sharedManager] placeCallOnHold:self];
    
    self.holdStarted = [NSDate date];
    
    //TODO: talk to acctual SIP interface to find out call status, etc, and hold/unhold
    _hold = hold;
    
    _hold = _lineSession.mHoldSate;
    [self didChangeValueForKey:@"hold"];
}

-(BOOL)hold
{
    //TODO: get actual hold status from SIP interface.
    return _hold;
}

-(void)answerCall
{
    [[JCCallCardManager sharedManager] answerCall:self];
}

-(void)endCall
{
    [[JCCallCardManager sharedManager] hangUpCall:self remote:NO];
}

-(void)endCallRemote
{
	[[JCCallCardManager sharedManager] hangUpCall:self remote:YES];
}

-(NSString *)callerId
{
    if (_callerId)
        return _callerId;
    return @"Unknown";
}

-(void)setLineSession:(JCLineSession *)lineSession
{
	_lineSession = lineSession;
	_lineSession.delegate = self;
	
	_callerId = _lineSession.callTitle;
	_dialNumber = _lineSession.callDetail;
	_identifer = [NSString stringWithFormat:@"%ld", _lineSession.mSessionId];
	
	[self callStateDidChange:_lineSession.mSessionId callState:_lineSession.mCallState];
}

#pragma mark - Line Session Delegate
-(void)callStateDidChange:(long)sessionId callState:(JCCall)callState
{
	[self willChangeValueForKey:@"status"];
	
	switch (callState) {
		case  JCNoCall:
//			_dialNumber = @"Connecting";
			break;
		case JCCallRinging:
//			_dialNumber = @"Ringing";
			break;
		case JCCallConnected:
//			_dialNumber = _lineSession.callDetail;
			break;
		case JCCallFailed:
		case JCCallCanceled:
			[self endCallRemote];
			break;
		case JCCallOnHold:
		case JCCALlOffHold:
			[self setHold:YES];
			break;
		default:
			break;
	}
	
	[self didChangeValueForKey:@"status"];
	NSLog(@"State Changed For Session %ld - State: %u", sessionId, callState);
}


@end
