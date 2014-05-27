//
//  JCSpeakerView.m
//  JiveOne
//
//  Created by Doug on 5/27/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCSpeakerView.h"
#import "JCStyleKit.h"

@interface JCSpeakerView()
@property BOOL isSelected;
@end

@implementation JCSpeakerView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.isSelected = NO;
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    [JCStyleKit drawSpeakerButtonWithSpeakerFrame:self.bounds speakerIsSelected:self.isSelected];
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.isSelected = !self.isSelected;
    [self setNeedsDisplay];
}


@end
