//
//  JCIconViews.m
//  JiveOne
//
//  Created by Plen on 6/23/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCIconViews.h"
#import "JCStyleKit.h"

@implementation JCIconViews

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
    // Drawing code
    [JCStyleKit drawDefaultAvatarLogin];
}


@end
