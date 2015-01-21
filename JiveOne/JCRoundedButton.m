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

#define DEFAULT_SELECTED_BACKGROUND_COLOR [UIColor whiteColor]

@implementation JCRoundedButton

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        _selectedBackgroundColor = DEFAULT_SELECTED_BACKGROUND_COLOR;
    }
    return self;
}


-(void)awakeFromNib
{
    _defaultBackgroundColor = self.backgroundColor;
    self.selected = self.selected;
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    self.layer.cornerRadius = self.bounds.size.width/2;
    self.layer.masksToBounds = true;
    
    self.selected = self.selected;
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

@end
