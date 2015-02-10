//
//  JCMessageView.m
//  JiveOne
//
//  Created by Robert Barclay on 2/10/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#define DEFAULT_MESSAGE_BUBBLE_COLOR [UIColor whiteColor]
#define DEFAULT_MESSAGE_CORNER_RADIUS 6
#define DEFAULT_MESSAGE_MARGIN 8

#import "JCMessageView.h"

@implementation JCMessageView

-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        _bubbleColor = DEFAULT_MESSAGE_BUBBLE_COLOR;
        _cornerRadius = DEFAULT_MESSAGE_CORNER_RADIUS;
        _margin = DEFAULT_MESSAGE_MARGIN;
    }
    return self;
}

-(void)setBubbleColor:(UIColor *)bubbleColor
{
    _bubbleColor = bubbleColor;
    [self setNeedsDisplay];
}

-(void)setCornerRadius:(NSInteger)cornerRadius
{
    _cornerRadius = cornerRadius;
    [self setNeedsDisplay];
}

-(void)setMargin:(NSInteger)margin
{
    _margin = margin;
    [self setNeedsDisplay];
}

@end
