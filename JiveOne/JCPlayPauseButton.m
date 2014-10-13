//
//  JCPlayPauseView.m
//  JiveOne
//
//  Created by Doug on 5/28/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCPlayPauseButton.h"
#import "JCStyleKit.h"

@implementation JCPlayPauseButton

-(void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    [JCStyleKit drawPlay_PauseWithFrame:self.bounds playPauseDisplaysPlay:!self.selected];
}

@end
