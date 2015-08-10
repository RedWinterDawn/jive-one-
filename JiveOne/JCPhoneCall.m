//
//  JCCall.m
//  JiveOne
//
//  Created by Robert Barclay on 10/2/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCPhoneCall.h"

@implementation JCPhoneCall

-(instancetype)initWithSession:(JCPhoneSipSession *)lineSession
{
    self = [super init];
    if (self)
    {
        _lineSession = lineSession;
        _started = [NSDate date];
    }
    return self;
}

#pragma mark - Actions -

-(void)answerCall:(CompletionHandler)completion
{
    [self.delegate answerCall:self completion:completion];
}

-(void)endCall:(CompletionHandler)completion
{
    [self.delegate hangUpCall:self completion:completion];
}

-(void)holdCall:(CompletionHandler)completion
{
    [self.delegate holdCall:self completion:^(BOOL success, NSError *error) {
        self.holdStarted = [NSDate date];
        if (completion) {
            completion(success, error);
        }
    }];
}

-(void)unholdCall:(CompletionHandler)completion
{
    [self.delegate unholdCall:self completion:^(BOOL success, NSError *error) {
        self.holdStarted = nil;
        if (completion) {
            completion(success, error);
        }
    }];
}

#pragma mark - Getters -

-(NSString *)callerId
{
    return _lineSession.number.titleText;
}

-(NSString *)dialNumber
{
    return _lineSession.number.detailText;
}

@end
