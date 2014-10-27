//
//  JCConferenceCallCard.m
//  JiveOne
//
//  Created by Robert Barclay on 10/27/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCConferenceCallCard.h"

@interface JCConferenceCallCard ()
{
    NSMutableArray *_calls;
}

@end

@implementation JCConferenceCallCard

-(instancetype)initWithCalls:(NSArray *)calls
{
    self = [self init];
    if (self)
    {
        [self addCalls:calls];
    }
    return self;
}

-(instancetype)initWithLineSessions:(NSArray *)sessions
{
    self = [self init];
    if (self)
    {
        for (id session in sessions)
        {
            if ([session isKindOfClass:[JCLineSession class]])
            {
                [self addCall:[[JCCallCard alloc] initWithLineSession:(JCLineSession *)session]];
            }
        }
    }
    return self;
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:kJCCallCardStatusChangeKey])
    {
        // do something for conference calls.
    }
}

-(void)dealloc
{
    if (_calls) {
        [self removeCalls:_calls];
    }
}

#pragma mark - Getters -

-(NSString *)callerId
{
    return NSLocalizedString(@"Conference", null) ;
}

-(NSString *)dialNumber
{
    NSMutableString *output = [NSMutableString string];
    for(JCCallCard *callCard in _calls)
    {
        if (output.length > 0)
        {
            [output appendString:@","];
        }
        [output appendString:callCard.callerId];
    }
    return output;
}

#pragma mark - Methods -

-(void)addCall:(JCCallCard *)call
{
    if (!_calls) {
        _calls = [NSMutableArray array];
    }
    
    if (![_calls containsObject:call]) {
        [_calls addObject:call];
        [call addObserver:self forKeyPath:kJCCallCardStatusChangeKey options:NSKeyValueObservingOptionPrior context:NULL];
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
        [call removeObserver:self forKeyPath:kJCCallCardStatusChangeKey];
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


@end
