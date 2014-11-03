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

-(void)awakeFromNib
{
    // Hack for iOS7 compatibility
    if ([[UIDevice currentDevice].systemVersion floatValue] < 8.0f)
    {
        UIColor *backgroundColor = self.backgroundColor;
        self.backgroundColor = [UIColor clearColor];
        UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
        view.backgroundColor = backgroundColor;
        self.backgroundView = view;
    }
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    // Hack for iOS7 compatibility
    if ([[UIDevice currentDevice].systemVersion floatValue] < 8.0f)
    {
        CGRect rect = self.backgroundView.bounds;
        rect.size.height = self.frame.size.height - 1;
        self.backgroundView.bounds = rect;
    }
}

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
