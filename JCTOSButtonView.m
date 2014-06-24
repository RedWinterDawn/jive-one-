//
//  JCTOSButtonView.m
//  JiveOne
//
//  Created by Doug on 6/24/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCTOSButtonView.h"

@implementation JCTOSButtonView
- (void)drawRect:(CGRect)rect
{
    [JCStyleKit drawTOS_ButtonWithFrame:self.bounds];
}
@end
