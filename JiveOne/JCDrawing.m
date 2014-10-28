//
//  JCDrawing.m
//  JiveOne
//
//  Created by Robert Barclay on 10/28/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCDrawing.h"

JCDrawingLine JCDrawingLineMake(CGFloat width, CGColorRef color)
{
    JCDrawingLine line;
    line.width = width;
    line.color = color;
    return line;
}

void JCDrawingContextDrawLineAtPosition(CGContextRef context, JCDrawingLine line, CGRect rect, JCDrawingLinePosition position)
{
    CGFloat y = 0;
    CGFloat x = 0;
    CGFloat inset = line.width/2.0f;
    switch (position)
    {
        case kJCDrawingLinePositionTop:
            y = CGRectGetMinY(rect) + inset;
            break;
        case kJCDrawingLinePositionBottom:
            y = CGRectGetMaxY(rect) - inset;
            break;
        case kJCDrawingLinePositionLeft:
            x = CGRectGetMinX(rect) + inset;
            break;
        case kJCDrawingLinePositionRight:
            x = CGRectGetMaxX(rect) - inset;
            break;
        default:
            break;
    }
    
    CGContextSaveGState(context);
    if (position == kJCDrawingLinePositionTop || position == kJCDrawingLinePositionBottom)
    {
        CGContextMoveToPoint(context, CGRectGetMinX(rect), y);
        CGContextAddLineToPoint(context, CGRectGetMaxX(rect), y);
    }
    else
    {
        CGContextMoveToPoint(context, x, CGRectGetMinY(rect));
        CGContextAddLineToPoint(context, x, CGRectGetMaxY(rect));
    }
    
    CGContextSetStrokeColorWithColor(context, line.color);
    CGContextSetLineWidth(context, line.width);
    CGContextStrokePath(context);
    
    CGContextRestoreGState(context);
}

void JCDrawingContextDrawLineAtOffset(CGContextRef context, JCDrawingLine line, CGRect rect, CGFloat offset)
{
    CGContextSaveGState(context);
    
    CGContextMoveToPoint(context, CGRectGetMinX(rect), offset);
    CGContextAddLineToPoint(context, CGRectGetMaxX(rect), offset);
    
    CGContextSetStrokeColorWithColor(context, line.color);
    CGContextSetLineWidth(context, line.width);
    CGContextStrokePath(context);
    
    CGContextRestoreGState(context);
}

void JCDrawingContextDrawLineAtPoints(CGContextRef context, JCDrawingLine line, CGRect rect, CGPoint startPoint, CGPoint endPoint)
{
    CGContextSaveGState(context);
    
    CGContextMoveToPoint(context, startPoint.x, startPoint.y);
    CGContextAddLineToPoint(context, endPoint.x, endPoint.y);
    
    CGContextSetStrokeColorWithColor(context, line.color);
    CGContextSetLineWidth(context, line.width);
    CGContextStrokePath(context);
    
    CGContextRestoreGState(context);
}

CALayer *JCDrawingLayerCreateLineBorderAtPosition(JCDrawingLinePosition position, CGRect rect, JCDrawingLine line)
{
    CGFloat y = 0;
    CGFloat x = 0;
    CGFloat inset = line.width/2.0f;
    switch (position)
    {
        case kJCDrawingLinePositionTop:
            y = CGRectGetMinY(rect) + inset;
            break;
        case kJCDrawingLinePositionBottom:
            y = CGRectGetMaxY(rect) - inset;
            break;
        case kJCDrawingLinePositionLeft:
            x = CGRectGetMinX(rect) + inset;
            break;
        case kJCDrawingLinePositionRight:
            x = CGRectGetMaxX(rect) - inset;
            break;
        default:
            break;
    }
    CGPoint startPoint;
    CGPoint endPoint;
    
    if (position == kJCDrawingLinePositionTop || position == kJCDrawingLinePositionBottom)
    {
        startPoint = CGPointMake(CGRectGetMinX(rect), y);
        endPoint = CGPointMake(CGRectGetMaxX(rect), y);
    }
    else
    {
        startPoint = CGPointMake(x, CGRectGetMinY(rect));
        endPoint = CGPointMake(x, CGRectGetMaxY(rect));
    }
    
    CALayer *lineLayer = [CALayer layer];
    JCDrawingLayerDrawLineAtPoints(lineLayer, line, startPoint, endPoint);
    return lineLayer;
}

void JCDrawingLayerDrawLineAtPoints(CALayer *layer, JCDrawingLine line, CGPoint startPoint, CGPoint endPoint)
{
    CGPoint center = { 0.5 * (startPoint.x + endPoint.x), 0.5 * (startPoint.y + endPoint.y) };
    CGFloat length = sqrt((startPoint.x - endPoint.x) * (startPoint.x - endPoint.x) + (startPoint.y - endPoint.y) * (startPoint.y - endPoint.y));
    CGFloat angle = atan2(startPoint.y - endPoint.y, startPoint.x - endPoint.x);
    
    layer.position = center;
    layer.bounds = (CGRect) { {0, 0}, { length + line.width, line.width } };
    layer.transform = CATransform3DMakeRotation(angle, 0, 0, 1);
}
