//
//  JCTableViewCell.m
//  JiveOne
//
//  Created by Robert Barclay on 10/28/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCTableViewCell.h"
#import "JCDrawing.h"

@implementation JCTableViewCell

-(void)prepareForReuse
{
    [super prepareForReuse];
    
    _top = false;
}

-(void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    JCDrawingLine drawingLine = JCDrawingLineMake(0.5, self.seperatorColor.CGColor);
    JCDrawingContextDrawLineAtPosition(context, drawingLine, rect, kJCDrawingLinePositionBottom);
    if (_top)
        JCDrawingContextDrawLineAtPosition(context, drawingLine, rect, kJCDrawingLinePositionTop);
}

@end
