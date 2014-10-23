//
//  JCMergeButton.m
//  JiveOne
//
//  Created by Robert Barclay on 10/14/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCMergeButton.h"

@interface JCMergeButton ()

@property (nonatomic, strong) UIImage *mergeImageNormal;
@property (nonatomic, strong) UIImage *mergeImageHighlighted;
@property (nonatomic, strong) UIImage *splitImageNormal;
@property (nonatomic, strong) UIImage *splitImageHighlighted;

@property (nonatomic, strong) UIColor *defaultColor;

@end

@implementation JCMergeButton

-(UIImage *)mergeImageNormal
{
    if (!_mergeImageNormal) {
        _mergeImageNormal = [UIImage imageNamed:@"white-merge"];
    }
    return _mergeImageNormal;
}

-(UIImage *)mergeImageHighlighted
{
    if (!_mergeImageHighlighted) {
        _mergeImageHighlighted = [UIImage imageNamed:@"blue-merge"];
    }
    return _mergeImageHighlighted;
}

-(UIImage *)splitImageNormal
{
    if (!_splitImageNormal) {
        _splitImageNormal = [UIImage imageNamed:@"white-split"];
    }
    return _splitImageNormal;
}

-(UIImage *)splitImageHighlighted
{
    if (!_splitImageHighlighted) {
        _splitImageHighlighted = [UIImage imageNamed:@"blue-split"];
    }
    return _splitImageHighlighted;
}

-(void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    
    if (selected) {
        [self setImage:self.splitImageNormal forState:UIControlStateNormal];
        [self setImage:self.splitImageNormal forState:UIControlStateSelected];
        self.backgroundColor = _defaultBackgroundColor;
    }
    else
    {
        [self setImage:self.mergeImageNormal forState:UIControlStateNormal];
        [self setImage:self.mergeImageNormal forState:UIControlStateSelected];
        self.backgroundColor = _defaultBackgroundColor;
    }
}

@end
