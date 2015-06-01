//
//  JCRoundedView.m
//  JiveOne
//
//  Created by P Leonard on 9/30/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCRoundedButton.h"
#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>
#import "JCDrawing.h"

#define DEFAULT_SELECTED_BACKGROUND_COLOR [UIColor whiteColor]
#define DEFAULT_ROUNDED_BUTTON_BORDER_WIDTH 0
#define DEFAULT_ROUNDED_BUTTON_BORDER_COLOR [UIColor clearColor]

@implementation JCRoundedButton

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        _selectedBackgroundColor = DEFAULT_SELECTED_BACKGROUND_COLOR;
        self.borderWidth = DEFAULT_ROUNDED_BUTTON_BORDER_WIDTH;
        self.borderColor = DEFAULT_ROUNDED_BUTTON_BORDER_COLOR;
    }
    return self;
}


-(void)awakeFromNib
{
    _defaultBackgroundColor = self.backgroundColor;
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    if (_cornerRadius == 0 ) {
        self.cornerRadius = self.bounds.size.width/2;
    }
}
-(void)setEnabled:(BOOL)enabled{
    [super setEnabled:enabled];
    if (enabled) {
        self.backgroundColor = _defaultBackgroundColor;
    } else{
        self.backgroundColor = [_defaultBackgroundColor colorWithAlphaComponent: 0.05];
    }
}
-(void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    if (selected) {
        self.backgroundColor = _selectedBackgroundColor;
    }
    else{
        self.backgroundColor = _defaultBackgroundColor; // [UIColor colorWithWhite:1 alpha:.2];
    }
}

#pragma mark - Setters -

-(void)setCornerRadius:(CGFloat)cornerRadius
{
    _cornerRadius = cornerRadius;
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

-(CGFloat)borderWidth
{
    return self.layer.borderWidth;
}

-(UIColor *)borderColor
{
    return [UIColor colorWithCGColor:self.layer.borderColor];
}


@end
