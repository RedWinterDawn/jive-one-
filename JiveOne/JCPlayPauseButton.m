//
//  JCPlayPauseButton.m
//  JiveOne
//
//  Created by Robert Barclay on 5/29/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCPlayPauseButton.h"
#import "JCDrawing.h"

NSString *const kJCPlayPauseButtonImageCacheName = @"JCPlayPauseButton.imageCache";

@interface JCPlayPauseButton ()
{
    NSCache *_imageCache;
}

@end

@implementation JCPlayPauseButton

-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        _imageCache = [[NSCache alloc] init];
        _imageCache.name = kJCPlayPauseButtonImageCacheName;
        _imageCache.countLimit = 8; // holds all 8 states in cache.
        _paused = TRUE; // our initial state is paused.
    }
    return self;
}

-(void)awakeFromNib
{
    [super awakeFromNib];
    
    [self setImageForState:UIControlStateNormal paused:_paused];
    [self setImageForState:UIControlStateHighlighted paused:_paused];
    [self setImageForState:UIControlStateSelected paused:_paused];
    [self setImageForState:UIControlStateDisabled paused:_paused];
}

-(void)setPaused:(BOOL)paused
{
    _paused = paused;
    [self setImageForState:UIControlStateNormal paused:_paused];
    [self setImageForState:UIControlStateHighlighted paused:_paused];
    [self setImageForState:UIControlStateSelected paused:_paused];
    [self setImageForState:UIControlStateDisabled paused:_paused];
}

#pragma mark - Private -

-(void)setImageForState:(UIControlState)state paused:(BOOL)paused
{
    UIImage *imageForState = [self imageForState:state isPaused:paused];
    [super setImage:imageForState forState:state];
}

-(UIImage *)imageForState:(UIControlState)state isPaused:(BOOL)paused
{
    NSString *key = [NSString stringWithFormat:@"%hhd-%lu", paused, (unsigned long)state];
    UIImage *image = [_imageCache objectForKey:key];
    if (image) {
        return image;
    }
    
    if (paused) {
        image = self.playImage;
    } else {
        image = self.pauseImage;
    }
    
    image = [self maskedImageFromImage:image state:state];
    [_imageCache setObject:image forKey:key];
    return image;
}

-(UIImage *)maskedImageFromImage:(UIImage *)image state:(UIControlState)state
{
    switch (state) {
        case UIControlStateDisabled:
        {
            UIColor *color = [self.tintColor colorWithAlphaComponent:0.5];
            return JCDrawingCreateMaskedImageFromImageMask(image, color.CGColor);
        }
        case UIControlStateSelected:
        case UIControlStateHighlighted:
        {
            UIColor *color = self.selectedColor ? self.selectedColor : self.tintColor;
            return JCDrawingCreateMaskedImageFromImageMask(image, color.CGColor);
        }
        default:
            return JCDrawingCreateMaskedImageFromImageMask(image, self.tintColor.CGColor);
    }
}

@end
