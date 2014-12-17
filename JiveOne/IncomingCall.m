//
//  IncommingCall.m
//  JiveOne
//
//  Created by P Leonard on 10/10/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "IncomingCall.h"
#import <MagicalRecord/MagicalRecord.h>

NSString *const kIncomingCallEntityName = @"IncomingCall";

@implementation IncomingCall

-(UIImage *)icon
{
    // Get icon, but only ever once.
    static UIImage *incomingCallIcon;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        incomingCallIcon = [UIImage imageNamed:@"green-incoming"];
    });
        
    return incomingCallIcon;
}

@end


@implementation IncomingCall (MagicalRecord)

+(void)addIncommingCallWithLineSession:(JCLineSession *)session line:(Line *)line
{
    [IncomingCall addCallEntity:kIncomingCallEntityName line:line lineSession:session read:YES];
}

@end