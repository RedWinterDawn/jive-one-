//
//  JCMaskedRoundedButton.m
//  JiveOne
//
//  Created by Robert Barclay on 5/29/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCMaskedRoundedButton.h"
#import "JCDrawing.h"

@interface JCMaskedRoundedButton (){
    UIColor *_defaultBorderColor;
}

@end

@implementation JCMaskedRoundedButton

-(void)awakeFromNib
{
    [super awakeFromNib];
    
    _defaultBorderColor = self.borderColor;
    
    // Check to see if we have an image. if we do we want to check each state. If they do not have
    // a state we will set one using the tint color.
    UIImage *image = [self imageForState:UIControlStateNormal];
    if (!image) {
        return;
    }
    
    UIImage *maskedImage = JCDrawingCreateMaskedImageFromImageMask(image, self.tintColor.CGColor);
    [self setImage:maskedImage forState:UIControlStateNormal];
    
    UIColor *selectedColor = self.selectedColor;
    maskedImage = JCDrawingCreateMaskedImageFromImageMask(image, selectedColor.CGColor);
    [self setImage:maskedImage forState:UIControlStateHighlighted];
    [self setImage:maskedImage forState:UIControlStateSelected];
    
    maskedImage = JCDrawingCreateMaskedImageFromImageMask(image, [UIColor colorWithWhite:0 alpha:0.5].CGColor);
    [self setImage:maskedImage forState:UIControlStateDisabled];
}

-(void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    
    if (selected) {
        self.borderColor = self.selectedColor;
    } else {
        self.borderColor = _defaultBorderColor;
    }
}

-(void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    
    if (highlighted) {
        self.borderColor = self.selectedColor;
    } else {
        self.borderColor = _defaultBorderColor;
    }
}

@end
