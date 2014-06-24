//
//  JCLogOutButton.m
//  JiveOne
//
//  Created by Doug on 6/24/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCLogOutButton.h"

@implementation JCLogOutButton
- (void)drawRect:(CGRect)rect
{
    [JCStyleKit drawLogOutButtonWithFrame:self.bounds];
}
@end
