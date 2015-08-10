//
//  MissedCall.m
//  JiveOne
//
//  Created by P Leonard on 10/10/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "MissedCall.h"

NSString *const kMissedCallEntityName = @"MissedCall";

@interface MissedCall ()
{
    
}

@end

@implementation MissedCall
-(UIImage *)icon
{
    // Get icon, but only ever once.
    static UIImage *missedCallIcon;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        missedCallIcon = [UIImage imageNamed:@"red-missed"];
    });
    
    return missedCallIcon;
}

@end

@implementation MissedCall (MagicalRecord)

+(void)addMissedCallWithLineSession:(JCPhoneSipSession *)session line:(Line *)line
{
    [MissedCall addCallEntity:kMissedCallEntityName line:line lineSession:session read:NO];
}


@end