//
//  JCSpeakerView.m
//  JiveOne
//
//  Created by Doug on 5/27/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCSpeakerView.h"
#import "JCVoiceCell.h"
#import "JCStyleKit.h"

@interface JCSpeakerView()
@property (nonatomic) BOOL isSelected;
@property (nonatomic) JCVoiceCell* parentCell;
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

//- (void)drawRect:(CGRect)rect
//{
//   [JCStyleKit drawSpeakerButtonWithSpeakerFrame:self.bounds speakerIsSelected:self.isSelected];
//}

-(void)setIsSelected:(BOOL)isSelected
{
    _isSelected = isSelected;
    [self setNeedsDisplay];

}
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.parentCell.delegate && [self.parentCell.delegate respondsToSelector:@selector(voicecellSpeakerTouched:)]) {
        [self.parentCell.delegate voicecellSpeakerTouched:YES];
    }
}

- (JCVoiceCell*)parentCell
{
    if (![self.superview.superview.superview isKindOfClass:[JCVoiceCell class]]) {
        NSLog(@"View Hierarchy is messed up for JCSpeakerView");
        return nil;
    }
    return (JCVoiceCell*)self.superview.superview.superview;
}
@end
