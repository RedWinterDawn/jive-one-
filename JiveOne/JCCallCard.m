//
//  JCCall.m
//  JiveOne
//
//  Created by Robert Barclay on 10/2/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCCallCard.h"
#import "JCCallCardManager.h"

NSString *const kJCCallCardStatusChangeKey = @"status";
NSString *const kJCCallCardHoldKey = @"hold";

NSString *const kJCCallCardConferenceString = @"Conference";

@interface JCCallCard ()
{
    NSMutableArray *_calls;
    BOOL _hold;
}

@end


@implementation JCCallCard

-(id)init
{
    self = [super init];
    if (self) {
        self.started = [NSDate date];
    }
    return self;
}

-(id)initWithLineSession:(JCLineSession *)lineSession
{
    self = [self init];
    if (self) {
        self.lineSession = lineSession;
    }
    return self;
}

-(id)initWithCalls:(NSArray *)calls
{
    self = [self init];
    if (self) {
        [self addCalls:calls];
    }
    return self;
}

-(id)initWithLineSessions:(NSArray *)sessions
{
    self = [self init];
    if (self) {
        for (id session in sessions){
            if ([session isKindOfClass:[JCLineSession class]]){
                [self addCall:[[JCCallCard alloc] initWithLineSession:(JCLineSession *)session]];
            }
        }
    }
    return self;
}

#pragma mark - Actions -

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

#pragma mark Conference Calls

-(void)addCall:(JCCallCard *)call
{
    if (!_calls) {
        _calls = [NSMutableArray array];
    }
    
    if (![_calls containsObject:call]) {
        [_calls addObject:call];
    }
}

-(void)addCalls:(NSArray *)calls
{
    for (id object in calls)
    {
        if ([object isKindOfClass:[JCCallCard class]])
        {
            [self addCall:(JCCallCard *)object];
        }
    }
}

-(void)removeCall:(JCCallCard *)call
{
    if (!_calls)
    {
        return;
    }
    
    if ([_calls containsObject:call])
    {
        [_calls removeObject:call];
    }
}

-(void)removeCalls:(NSArray *)calls
{
    for (id object in calls)
    {
        if ([object isKindOfClass:[JCCallCard class]])
        {
            [self removeCall:(JCCallCard *)object];
        }
    }
}

#pragma mark - Setters -

-(void)setLineSession:(JCLineSession *)lineSession
{
    _lineSession = lineSession;
    _lineSession.delegate = self;
    self.callState = _lineSession.mCallState;
}

-(void)setHold:(BOOL)hold
{
    [self willChangeValueForKey:kJCCallCardHoldKey];
    if (self.isConference) {
        _hold = hold;
    }
    else
    {
        [[JCCallCardManager sharedManager] toggleCallHold:self];
    }
    self.holdStarted = [NSDate date];
    [self didChangeValueForKey:kJCCallCardHoldKey];
}

-(void)setCallState:(JCCall)callState
{
    [self willChangeValueForKey:kJCCallCardStatusChangeKey];
    _callState = callState;
    switch (callState) {
        case JCCallFailed:
        case JCCallCanceled:
            [self endCallRemote];
            break;
        case JCCallOnHold:
        case JCCALlOffHold:
            self.hold = YES;
            break;
        default:
            break;
    }
    
    [self didChangeValueForKey:kJCCallCardStatusChangeKey];
}

#pragma mark - Getters -

-(BOOL)hold
{
    if (self.isConference)
    {
        return _hold;
    }
    return _lineSession.mHoldSate;
}

-(NSString *)callerId
{
    if (self.isConference)
        return NSLocalizedString(kJCCallCardConferenceString, null) ;
    return _lineSession.callTitle;
}

-(NSString *)dialNumber
{
    if (self.isConference) {
        NSMutableString *output = [NSMutableString string];
        for(JCCallCard *callCard in _calls) {
            if (output.length > 0) {
                [output appendString:@","];
            }
            [output appendString:callCard.callerId];
        }
        return output;
    }
    
    return _lineSession.callDetail;
}

-(NSString *)identifer
{
    return [NSString stringWithFormat:@"%ld", _lineSession.mSessionId];
}

-(bool)isConference
{
    return (_calls && _calls.count > 0);
}

#pragma mark - Delegate Handlers -

#pragma mark Line Session Delegate

-(void)callStateDidChange:(long)sessionId callState:(JCCall)callState
{
    self.callState = callState;
}


@end
