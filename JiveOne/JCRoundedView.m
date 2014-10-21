//
//  JCRoundedView.m
//  JiveOne
//
//  Created by Robert Barclay on 10/21/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCRoundedView.h"
#import <QuartzCore/QuartzCore.h>

@implementation JCRoundedView

-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.cornerRadius = DEFAULT_ROUNDED_VIEW_CORNER_RADIUS;
        self.borderWidth = DEFAULT_ROUNDED_VIEW_BORDER_WIDTH;
        self.borderColor = DEFAULT_ROUNDED_VIEW_BORDER_COLOR;
    }
    return self;
}

#pragma mark - Setters -

-(void)setCornerRadius:(CGFloat)cornerRadius
{
    self.layer.cornerRadius = cornerRadius;
    self.layer.masksToBounds = true;
}

-(void)setBorderColor:(UIColor *)borderColor
{
    self.layer.borderColor = borderColor.CGColor;
}

-(void)setBorderWidth:(CGFloat)borderWidth
{
    self.layer.borderWidth = borderWidth;
}

#pragma mark - Getters -

-(CGFloat)cornerRadius
{
    return self.layer.cornerRadius;
}

-(CGFloat)borderWidth
{
    return self.layer.borderWidth;
}

-(UIColor *)borderColor
{
    return [UIColor colorWithCGColor:self.layer.borderColor];
}

@end
