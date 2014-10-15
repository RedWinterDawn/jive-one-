//
//  JCDeleteView.m
//  JiveOne
//
//  Created by Doug on 5/27/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCDeleteButton.h"
#import "JCStyleKit.h"

@implementation JCDeleteButton

-(void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    [JCStyleKit drawTrashButtonWithOuterFrame:self.bounds selectWithDeleteColor:self.selected];
}

@end

