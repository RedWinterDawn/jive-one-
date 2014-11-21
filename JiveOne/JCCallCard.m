//
//  JCCall.m
//  JiveOne
//
//  Created by Robert Barclay on 10/2/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCCallCard.h"

NSString *const kJCCallCardStatusChangeKey = @"status";

@implementation JCCallCard

-(instancetype)init
{
    self = [super init];
    if (self)
    {
        self.started = [NSDate date];
    }
    return self;
}

-(instancetype)initWithLineSession:(JCLineSession *)lineSession
{
    self = [self init];
    if (self)
    {
        _lineSession = lineSession;
        [_lineSession addObserver:self forKeyPath:kJCLineSessionStateKey options:0 context:NULL];
        [_lineSession addObserver:self forKeyPath:@"hold" options:0 context:NULL];
    }
    return self;
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:kJCLineSessionStateKey] || [keyPath isEqualToString:@"hold"])
    {
        [self willChangeValueForKey:kJCCallCardStatusChangeKey];
        [self didChangeValueForKey:kJCCallCardStatusChangeKey];
    }
}

-(void)dealloc
{
    [self.lineSession removeObserver:self forKeyPath:kJCLineSessionStateKey];
    [self.lineSession removeObserver:self forKeyPath:@"hold"];
}

#pragma mark - Actions -

-(void)answerCall
{
    [self.delegate answerCall:self];
}

-(void)endCall
{
    [self.delegate hangUpCall:self];
}

#pragma mark - Setters -

-(void)setHold:(bool)hold
{
    [self.delegate setCallHold:hold forCall:self];
    if (hold) {
        self.holdStarted = [NSDate date];
    }
    else
    {
        self.holdStarted = nil;
    }
}


#pragma mark - Getters -

-(NSString *)callerId
{
    return _lineSession.callTitle;
}

-(NSString *)dialNumber
{
    return _lineSession.callDetail;
}

-(NSString *)identifer
{
    return [NSString stringWithFormat:@"%ld", _lineSession.mSessionId];
}

-(bool)isIncoming
{
    return _lineSession.mRecvCallState;
}

-(bool)isHolding
{
    return _lineSession.isHolding;
}

-(JCLineSessionState)callState
{
    return _lineSession.sessionState;
}

@end
