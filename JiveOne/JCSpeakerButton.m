//
//  JCSpeakerView.m
//  JiveOne
//
//  Created by Doug on 5/27/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCSpeakerButton.h"
#import "JCStyleKit.h"

@implementation JCSpeakerButton

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
   [JCStyleKit drawSpeakerButtonWithSpeakerFrame:self.bounds speakerIsSelected:self.isSelected];
}

@end
