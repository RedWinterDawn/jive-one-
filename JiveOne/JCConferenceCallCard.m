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

-(instancetype)initWithLineSessions:(NSSet *)sessions
{
    self = [super init];
    if (self) {
        _calls = [NSMutableArray array];
        for (id session in sessions) {
            if ([session isKindOfClass:[JCLineSession class]]) {
                JCCallCard *call = [[JCCallCard alloc] initWithLineSession:(JCLineSession *)session];
                [_calls addObject:call];
            }
        }
    }
    return self;
}

#pragma mark - Getters -

-(BOOL)isHolding
{
    for (JCCallCard *call in _calls) {
        if(!call.lineSession.isHolding) {
            return NO;
        }
    }
    return YES;
}

-(NSString *)callerId {
    return NSLocalizedString(@"Conference", null) ;
}

-(NSString *)dialNumber {
    NSMutableString *output = [NSMutableString string];
    for(JCCallCard *callCard in _calls) {
        if (output.length > 0) {
            [output appendString:@","];
        }
        [output appendString:callCard.callerId];
    }
    return output;
}

@end
