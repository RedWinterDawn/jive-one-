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
    [[JCCallCardManager sharedManager] placeCallOnHold:self];
    
    self.holdStarted = [NSDate date];
    
    //TODO: talk to acctual SIP interface to find out call status, etc, and hold/unhold
    _hold = hold;
}

-(BOOL)hold
{
    //TODO: get actual hold status from SIP interface.
    return _hold;
}

-(void)endCall
{
    [[JCCallCardManager sharedManager] hangUpCall:self];
    
}

-(NSString *)callerId
{
    if (_callerId)
        return _callerId;
    return @"Unknown";
}


@end
