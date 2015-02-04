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
        UIBezierPath* rectanglePath = [UIBezierPath bezierPathWithRoundedRect: CGRectMake(CGRectGetMinX(frame), CGRectGetMinY(frame), CGRectGetWidth(frame) - 19, CGRectGetHeight(frame)) byRoundingCorners: UIRectCornerTopLeft | UIRectCornerBottomLeft | UIRectCornerBottomRight cornerRadii: CGSizeMake(6, 6)];
        [rectanglePath closePath];
        [recColor setFill];
        [rectanglePath fill];


        //// Polygon Drawing
        UIBezierPath* polygonPath = UIBezierPath.bezierPath;
        [polygonPath moveToPoint: CGPointMake(CGRectGetMaxX(frame) - 35, CGRectGetMinY(frame) + 45.75)];
        [polygonPath addLineToPoint: CGPointMake(CGRectGetMaxX(frame) + 0.51, CGRectGetMinY(frame) - 0.37)];
        [polygonPath addLineToPoint: CGPointMake(CGRectGetMaxX(frame) - 70.51, CGRectGetMinY(frame) - 0.38)];
        [polygonPath closePath];
        [triangleColor setFill];
        [polygonPath fill];
}

@end
