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
            if ([session isKindOfClass:[JCPhoneSipSession class]]) {
                JCCallCard *call = [[JCCallCard alloc] initWithLineSession:(JCPhoneSipSession *)session];
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
    return NSLocalizedStringFromTable(@"Conference", @"Phone", @"Conference Caller id.");
}

-(NSString *)dialNumber {
    NSMutableString *output = [NSMutableString string];
    for(JCCallCard *callCard in _calls) {
        if (output.length > 0) {
            [output appendString:@","];
        }
        
        NSString *callerId = callCard.callerId;
        NSString *dialNumber = callCard.dialNumber;
        NSString *string = (callerId != nil) ? callerId : (dialNumber != nil) ? dialNumber : nil;
        if (string) {
            [output appendString:string];
        }
    }
    return output;
}

@end
