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

-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        _topLine = false;
        _bottomLine = true;
    }
    return self;
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    [self setNeedsDisplay];
}

-(void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (_topLine) {
        JCDrawingLine drawingLine = JCDrawingLineMake(0.5, self.seperatorColor.CGColor);
        JCDrawingContextDrawLineAtPosition(context, drawingLine, rect, kJCDrawingLinePositionTop);
    }
    
    if (_bottomLine) {
        JCDrawingLine drawingLine = JCDrawingLineMake(0.5, self.seperatorColor.CGColor);
        JCDrawingContextDrawLineAtPosition(context, drawingLine, rect, kJCDrawingLinePositionBottom);
    }
}

@end
