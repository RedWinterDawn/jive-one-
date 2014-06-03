//
//  JCPlayPauseView.m
//  JiveOne
//
//  Created by Doug on 5/28/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCPlayPauseView.h"
#import "JCVoiceCell.h"
#import "JCStyleKit.h"

@interface JCPlayPauseView()
@property (nonatomic) JCVoiceCell* parentCell;
@end

@implementation JCPlayPauseView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self setPlayPauseDisplaysPlay:YES];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Initialization code
        [self setPlayPauseDisplaysPlay:YES];
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    [JCStyleKit drawPlay_PauseWithFrame:self.bounds playPauseDisplaysPlay:self.playPauseDisplaysPlay];
}

-(void)setPlayPauseDisplaysPlay:(BOOL)playPauseDisplaysPlay
{
    _playPauseDisplaysPlay = playPauseDisplaysPlay;
    [self setNeedsDisplay];
}
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.playPauseDisplaysPlay = !self.playPauseDisplaysPlay;
    
    if (self.parentCell.delegate && [self.parentCell.delegate respondsToSelector:@selector(voiceCellPlayTapped:)]) {
        [self.parentCell.delegate voiceCellPlayTapped:self.parentCell];
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
