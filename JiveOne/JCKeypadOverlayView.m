//
//  JCKeypadView.m
//  JiveOne
//
//  Created by P Leonard on 10/7/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCKeypadOverlayView.h"

@implementation JCKeypadOverlayView

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    return CGRectContainsPoint(_keypadView.frame, point);
}

@end
