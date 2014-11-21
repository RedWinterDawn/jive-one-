//
//  OutGoingCall.m
//  JiveOne
//
//  Created by P Leonard on 10/10/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "OutgoingCall.h"

NSString *const kOutgoingCallEntityName = @"OutgoingCall";

@implementation OutgoingCall

-(UIImage *)icon
{
    // Get icon, but only ever once.
    static UIImage *outgoingCallIcon;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        outgoingCallIcon = [UIImage imageNamed:@"blue-outgoing"];
    });
    
    return outgoingCallIcon;
}

@end

@implementation OutgoingCall (MagicalRecord)

+(void)addOutgoingCallWithLineSession:(JCLineSession *)session
{
    [OutgoingCall addCallEntity:kOutgoingCallEntityName lineSession:session read:YES];
}

@end
