//
//  JCDrawing.h
//  JiveOne
//
//  Created by Robert Barclay on 10/28/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

@import Foundation;

typedef enum : NSUInteger {
    kJCDrawingLinePositionTop,
    kJCDrawingLinePositionBottom,
    kJCDrawingLinePositionLeft,
    kJCDrawingLinePositionRight
} JCDrawingLinePosition;

typedef struct JCDrawingLine {
    CGFloat width;
    CGColorRef color;
} JCDrawingLine;

JCDrawingLine JCDrawingLineMake(CGFloat width, CGColorRef color);

// Context Drawing
void JCDrawingContextDrawLineAtPosition(CGContextRef context, JCDrawingLine line, CGRect rect, JCDrawingLinePosition position);
void JCDrawingContextDrawLineAtOffset(CGContextRef context, JCDrawingLine line, CGRect rect, CGFloat offset);
void JCDrawingContextDrawLineAtPoints(CGContextRef context, JCDrawingLine line, CGRect rect, CGPoint startPoint, CGPoint endPoint);

// CA Layer Drawing
CALayer *JCDrawingLayerCreateLineBorderAtPosition(JCDrawingLinePosition position, CGRect rect, JCDrawingLine line);
void JCDrawingLayerDrawLineAtPoints(CALayer *layer, JCDrawingLine line, CGPoint startPoint, CGPoint endPoint);

UIImage *JCDrawingCreateMaskedImageFromImageMask(UIImage *image, CGColorRef color);
CGContextRef JCDrawingContextCreateWithSize(CGSize size);