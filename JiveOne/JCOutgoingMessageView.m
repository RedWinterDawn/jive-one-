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
//        UIColor* recColor = [UIColor lightGrayColor];
//        UIColor* triangleColor = [UIColor lightGrayColor];

    //// Rectangle Drawing
    UIBezierPath* rectanglePath = [UIBezierPath bezierPathWithRoundedRect: CGRectMake(CGRectGetMinX(frame), CGRectGetMinY(frame), CGRectGetWidth(frame) - 5, CGRectGetHeight(frame)) byRoundingCorners: UIRectCornerTopLeft | UIRectCornerBottomLeft | UIRectCornerBottomRight cornerRadii: CGSizeMake(6, 6)];
    [rectanglePath closePath];
    [UIColor.grayColor setFill];
    [rectanglePath fill];
    
    
    //// Bezier Drawing
    UIBezierPath* bezierPath = UIBezierPath.bezierPath;
    [bezierPath moveToPoint: CGPointMake(CGRectGetMaxX(frame) - 5, CGRectGetMinY(frame))];
    [bezierPath addLineToPoint: CGPointMake(CGRectGetMaxX(frame), CGRectGetMinY(frame))];
    [bezierPath addLineToPoint: CGPointMake(CGRectGetMaxX(frame) - 5, CGRectGetMinY(frame) + 5)];
    [bezierPath addLineToPoint: CGPointMake(CGRectGetMaxX(frame) - 5, CGRectGetMinY(frame))];
    [bezierPath closePath];
    [UIColor.grayColor setFill];
    [bezierPath fill];
}

@end
