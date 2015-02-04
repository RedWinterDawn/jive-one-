//
//  JCOutgoingMessageView.m
//  JiveOne
//
//  Created by P Leonard on 2/3/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCOutgoingMessageView.h"

@implementation JCOutgoingMessageView


-(void)drawRect:(CGRect)frame {
        //// Color Declarations
        UIColor* recColor = [UIColor lightGrayColor];
        UIColor* triangleColor = [UIColor lightGrayColor];

    //// Rectangle Drawing
    UIBezierPath* rectanglePath = [UIBezierPath bezierPathWithRoundedRect: CGRectMake(CGRectGetMinX(frame), CGRectGetMinY(frame), CGRectGetWidth(frame) - 8, CGRectGetHeight(frame)) byRoundingCorners: UIRectCornerTopLeft | UIRectCornerBottomLeft | UIRectCornerBottomRight cornerRadii: CGSizeMake(4, 4)];
    [rectanglePath closePath];
    [recColor setFill];
    [rectanglePath fill];
    
    
    //// Bezier Drawing
    UIBezierPath* bezierPath = UIBezierPath.bezierPath;
    [bezierPath moveToPoint: CGPointMake(CGRectGetMaxX(frame) - 9, CGRectGetMinY(frame))];
    [bezierPath addLineToPoint: CGPointMake(CGRectGetMaxX(frame) - 0, CGRectGetMinY(frame))];
    [bezierPath addLineToPoint: CGPointMake(CGRectGetMaxX(frame) - 9, CGRectGetMinY(frame) + 9)];
    [bezierPath addLineToPoint: CGPointMake(CGRectGetMaxX(frame) - 9, CGRectGetMinY(frame))];
    [bezierPath closePath];
    [triangleColor setFill];
    [bezierPath fill];
}

@end
