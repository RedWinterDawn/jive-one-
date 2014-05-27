//
//  JCDeleteView.m
//  JiveOne
//
//  Created by Doug on 5/27/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCDeleteView.h"
#import "JCStyleKit.h"

@interface JCDeleteView()
@property BOOL isSelected;
@end

@implementation JCDeleteView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.isSelected = NO;
    }
    return self;
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    [JCStyleKit drawTrashButtonWithOuterFrame:self.bounds selectWithDeleteColor:self.isSelected];

}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.isSelected = !self.isSelected;
    [self setNeedsDisplay];
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{

}
@end
