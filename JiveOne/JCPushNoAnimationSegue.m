//
//  JCPushNoAnimationSegue.m
//  JiveOne
//
//  Created by Robert Barclay on 2/26/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCPushNoAnimationSegue.h"

@implementation JCPushNoAnimationSegue

-(void) perform{
    [[[self sourceViewController] navigationController] pushViewController:[self destinationViewController] animated:NO];
}

@end
