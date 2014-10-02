//
//  JCCallCard.m
//  JiveOne
//
//  Created by P Leonard on 9/30/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCCallCardCollectionViewCell.h"
#import "JCCallCardManager.h"

@interface JCCallCardCollectionViewCell()
{
    NSTimer *_timer;
}
@end


@implementation JCCallCardCollectionViewCell

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    self.callerIdLabel.text = _callCard.callerId;
    self.dialedNumberLabel.dialString = _callCard.dialNumber;
    
    self.holdCallButton.selected = _callCard.hold;
    
    if (!_timer)
    {
        _timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(timerUpdate) userInfo:nil repeats:YES];
        [self timerUpdate];
    }
}

-(void)timerUpdate
{
    int secondsElapsed = -[_callCard.started timeIntervalSinceNow];
    int seconds = secondsElapsed % 60;
    int minutes = secondsElapsed / 60;
    self.elapsedTimeLabel.text = [NSString stringWithFormat:@"%02d:%02d", minutes, seconds];
}

-(void)setCallCard:(JCCallCard *)callCard
{
    _callCard = callCard;
    [self setNeedsLayout];
}

-(IBAction)hangup:(id)sender
{
    [_callCard endCall];
}

-(IBAction)toggleHold:(id)sender
{
    _callCard.hold = !_callCard.hold;
}

@end