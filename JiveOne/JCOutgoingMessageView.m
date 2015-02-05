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
    UIColor* white = [UIColor colorWithRed: 1 green: 1 blue: 1 alpha: 1];
    
    //// Rectangle Drawing
    UIBezierPath* rectanglePath = [UIBezierPath bezierPathWithRoundedRect: CGRectMake(CGRectGetMinX(frame), CGRectGetMinY(frame), CGRectGetWidth(frame) - 9, CGRectGetHeight(frame)) byRoundingCorners: UIRectCornerTopLeft | UIRectCornerBottomLeft | UIRectCornerBottomRight cornerRadii: CGSizeMake(6, 6)];
    [rectanglePath closePath];
    [white setFill];
    [rectanglePath fill];
    
    
    //// Bezier Drawing
    UIBezierPath* bezierPath = UIBezierPath.bezierPath;
    [bezierPath moveToPoint: CGPointMake(CGRectGetMaxX(frame) - 9, CGRectGetMinY(frame))];
    [bezierPath addLineToPoint: CGPointMake(CGRectGetMaxX(frame) - 1, CGRectGetMinY(frame))];
    [bezierPath addLineToPoint: CGPointMake(CGRectGetMaxX(frame) - 9, CGRectGetMinY(frame) + 8)];
    [bezierPath addLineToPoint: CGPointMake(CGRectGetMaxX(frame) - 9, CGRectGetMinY(frame))];
    [bezierPath closePath];
    [white setFill];
    [bezierPath fill];
}


        
@end
