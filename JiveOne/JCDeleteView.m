//
//  JCDeleteView.m
//  JiveOne
//
//  Created by Doug on 5/27/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCDeleteView.h"
#import "JCStyleKit.h"
#import "JCVoiceCell.h" 
#import "JCVoiceTableViewController.h"
@interface JCDeleteView()
@property BOOL isSelected;
@property (nonatomic) JCVoiceCell* parentCell;

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
    //close the cell then delete it.
    if (self.parentCell.delegate && [self.parentCell.delegate respondsToSelector:@selector(voiceCellDeleteTapped:)]) {
        if ([self.parentCell.delegate isKindOfClass:[JCVoiceTableViewController class]]) {
            [(JCVoiceTableViewController*)self.parentCell.delegate addOrRemoveSelectedIndexPath:self.parentCell.indexPath];
        }
        [self.parentCell.delegate voiceCellDeleteTapped:self.parentCell.indexPath];
    }
}

- (void)sendDeleteMessage
{
    
}

- (JCVoiceCell*)parentCell
{
    if (![self.superview.superview.superview isKindOfClass:[JCVoiceCell class]]) {
        NSLog(@"View Hierarchy is messed up for JCDeleteView");
        return nil;
    }
    return (JCVoiceCell*)self.superview.superview.superview;
}
@end
