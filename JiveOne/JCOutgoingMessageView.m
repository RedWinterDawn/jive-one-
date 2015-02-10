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
    
    //// Rectangle Drawing
    CGFloat x = CGRectGetMinX(frame);
    CGFloat y = CGRectGetMinY(frame);
    CGFloat w = CGRectGetWidth(frame) - _margin;
    CGFloat h = CGRectGetHeight(frame);
    CGSize cornerRadii = CGSizeMake(_cornerRadius, _cornerRadius);
    
    UIBezierPath* rectanglePath = [UIBezierPath bezierPathWithRoundedRect: CGRectMake(x, y, w, h) byRoundingCorners: UIRectCornerTopLeft | UIRectCornerBottomLeft | UIRectCornerBottomRight cornerRadii: cornerRadii];
    [rectanglePath closePath];
    [_bubbleColor setFill];
    [rectanglePath fill];
    
    //// Bezier Drawing
    UIBezierPath* bezierPath = UIBezierPath.bezierPath;
    [bezierPath moveToPoint: CGPointMake(CGRectGetMaxX(frame) - _margin, CGRectGetMinY(frame))];
    [bezierPath addLineToPoint: CGPointMake(CGRectGetMaxX(frame), CGRectGetMinY(frame))];
    [bezierPath addLineToPoint: CGPointMake(CGRectGetMaxX(frame) - _margin, CGRectGetMinY(frame) + _margin)];
    [bezierPath addLineToPoint: CGPointMake(CGRectGetMaxX(frame) - _margin, CGRectGetMinY(frame))];
    [bezierPath closePath];
    [_bubbleColor setFill];
    [bezierPath fill];
}

@end
