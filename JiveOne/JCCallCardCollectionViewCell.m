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
    NSTimer *_holdTimer;
}
@end


@implementation JCCallCardCollectionViewCell

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    self.callerIdLabel.text = _callCard.callerId;
    self.dialedNumberLabel.dialString = _callCard.dialNumber;
    
    self.holdCallButton.selected = _callCard.hold;
    [self showHoldStateAnimated:NO];
    
    if (!_timer)
    {
        _timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(timerUpdate) userInfo:nil repeats:YES];
        [self timerUpdate];
    }
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"hold"])
        [self showHoldStateAnimated:YES];
}

#pragma mark - Setters -

-(void)setCallCard:(JCCallCard *)callCard
{
    if (_callCard)
        [_callCard removeObserver:self forKeyPath:@"hold"];
    
    _callCard = callCard;
    [callCard addObserver:self forKeyPath:@"hold" options:NSKeyValueObservingOptionInitial context:NULL];
    
    [self setNeedsLayout];
}

#pragma mark - IBActions -

-(IBAction)hangup:(id)sender
{
    [_callCard endCall];
}

-(IBAction)toggleHold:(id)sender
{
    _callCard.hold = !_callCard.hold;
}

-(IBAction)answer:(id)sender
{
    [_callCard answerCall];
}

#pragma mark - Private -

-(void)timerUpdate
{
    int secondsElapsed = -[_callCard.started timeIntervalSinceNow];
    int seconds = secondsElapsed % 60;
    int minutes = secondsElapsed / 60;
    self.elapsedTimeLabel.text = [NSString stringWithFormat:@"%02d:%02d", minutes, seconds];
}

-(void)holdTimerUpdate
{
    int secondsElapsed = -[_callCard.holdStarted timeIntervalSinceNow];
    int seconds = secondsElapsed % 60;
    int minutes = secondsElapsed / 60;
    self.holdElapsedTimeLabel.text = [NSString stringWithFormat:@"%02d:%02d", minutes, seconds];
}

-(void)showHoldStateAnimated:(BOOL)animated
{
    __unsafe_unretained JCCallCardCollectionViewCell *weakSelf = self;
    if (_callCard.hold)
    {
        if (_holdTimer)
        {
            [_holdTimer invalidate];
            _holdTimer = nil;
        }
        
        _holdTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(holdTimerUpdate) userInfo:nil repeats:YES];
        [UIView animateWithDuration:(animated ? 0.3 : 0)
                         animations:^{
                             weakSelf.alpha = 0.5;
                         }];
    }
    else
    {
        [_holdTimer invalidate];
        _holdTimer = nil;
        
        [UIView animateWithDuration:(animated ? 0.3 : 0)
                         animations:^{
                             weakSelf.alpha = 1;
                         }];
    }
}



@end