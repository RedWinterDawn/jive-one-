//
//  JCView.m
//  JiveOne
//
//  Created by Robert Barclay on 10/28/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCView.h"
#import "JCDrawing.h"

@implementation JCView

-(void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    JCDrawingLine drawingLine = JCDrawingLineMake(0.5, self.seperatorColor.CGColor);
    JCDrawingContextDrawLineAtPosition(context, drawingLine, rect, kJCDrawingLinePositionBottom);
}

@end
