//
//  JCIncomingMessageView.m
//  JiveOne
//
//  Created by P Leonard on 2/3/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCIncomingMessageView.h"

@implementation JCIncomingMessageView

-(void)drawRect:(CGRect)frame {
    //// Color Declarations
    UIColor* recColor = [UIColor colorWithRed: 1 green: 1 blue: 1 alpha: 1];
    UIColor* triangleColor = [UIColor colorWithRed: 1 green: 1 blue: 1 alpha: 1];
    
    //// Rectangle Drawing
    UIBezierPath* rectanglePath = [UIBezierPath bezierPathWithRoundedRect: CGRectMake(CGRectGetMinX(frame) + 20, CGRectGetMinY(frame), CGRectGetWidth(frame) - 19, CGRectGetHeight(frame)) byRoundingCorners: UIRectCornerTopRight | UIRectCornerBottomLeft | UIRectCornerBottomRight cornerRadii: CGSizeMake(6, 6)];
    [rectanglePath closePath];
    [recColor setFill];
    [rectanglePath fill];
    
    
    //// Polygon Drawing
    UIBezierPath* polygonPath = UIBezierPath.bezierPath;
    [polygonPath moveToPoint: CGPointMake(CGRectGetMaxX(frame) - 232, CGRectGetMinY(frame) + 45.75)];
    [polygonPath addLineToPoint: CGPointMake(CGRectGetMaxX(frame) - 267.51, CGRectGetMinY(frame) - 0.37)];
    [polygonPath addLineToPoint: CGPointMake(CGRectGetMaxX(frame) - 196.49, CGRectGetMinY(frame) - 0.38)];
    [polygonPath closePath];
    [triangleColor setFill];
    [polygonPath fill];
}

@end
