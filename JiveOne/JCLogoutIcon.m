//
//  JCLogoutIcon.m
//  JiveOne
//
//  Created by Doug on 6/24/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCLogoutIcon.h"

@implementation JCLogoutIcon

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    [JCStyleKit drawLogoutIconWithFrame:self.bounds];
}

@end
