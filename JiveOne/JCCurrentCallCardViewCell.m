//
//  JCCurrentCallCardViewCell.m
//  JiveOne
//
//  Created by Robert Barclay on 10/16/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCCurrentCallCardViewCell.h"

#import <QuartzCore/QuartzCore.h>
#import "JCConferenceCallCard.h"

#define HOLD_ANIMATION_DURATION 0.5f
#define HOLD_ANIMATION_ALPHA 0.6f
#define HOLD_PULSE_ANIMATION_DURATION 1.0f
#define HOLD_PULSE_OPACITY_TO_VALUE 0.35f

NSString *const kJCCallCardCollectionViewCellHoldButtonPulseAnimationKey = @"pulse";
NSString *const kJCCallCardCollectionViewCellTimerFormat = @"%02d:%02d";

@interface JCCurrentCallCardViewCell ()
{
    NSTimer *_holdTimer;
    UIColor *_defaultCallActionsColor;
    CGFloat _currentCallCardInfoElevation;
    CGFloat _originalCurrentCallViewConstraint;
    CGFloat _originalEndCallButtonWidthConstraint;
    
    bool _showingHold;
    NSTimer *_timer;
}

@end

@implementation JCCurrentCallCardViewCell

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        _holdAnimationDuration = HOLD_ANIMATION_DURATION;
        _holdAnimationAlpha = HOLD_ANIMATION_ALPHA;
        _holdPulseAnimationDuration = HOLD_PULSE_ANIMATION_DURATION;
    }
    return self;
}

-(void)awakeFromNib
{
    [super awakeFromNib];
    
    _defaultCallActionsColor                = self.actionView.backgroundColor;
    _currentCallCardInfoElevation           = self.holdViewTopConstraint.constant;
    _originalCurrentCallViewConstraint      = self.cardInfoViewTopConstraint.constant;
    _originalEndCallButtonWidthConstraint   = self.endCallButtonWidthConstraint.constant;
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:kJCCallCardStatusChangeKey])
    {
        [self updateState:YES];
    }
}

-(void)dealloc
{
    if (self.callCard != nil)
    {
        [self.callCard removeObserver:self forKeyPath:kJCCallCardStatusChangeKey];
    }
}

-(void)willMoveToSuperview:(UIView *)newSuperview
{
    if (newSuperview)
        [self updateState:NO];
}

#pragma mark - Actions -

-(IBAction)toggleHold:(id)sender
{
    self.callCard.hold = !self.callCard.hold;
}


#pragma mark - Setters -

-(void)setCallCard:(JCCallCard *)callCard
{
    JCCallCard *currentCallCard = self.callCard;
    if (currentCallCard && currentCallCard != callCard) {
        [currentCallCard removeObserver:self forKeyPath:kJCCallCardStatusChangeKey];
    }
    
    [super setCallCard:callCard];
    [callCard addObserver:self forKeyPath:kJCCallCardStatusChangeKey options:0 context:NULL];
}

-(void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    
    self.elapsedTimeLabel.highlighted = highlighted;
}

#pragma mark - Private -


-(void)startTimer
{
    if (!_timer) {
        _timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(timerUpdate) userInfo:nil repeats:YES];
        [self timerUpdate];
    }
}

-(void)timerUpdate
{
    int secondsElapsed = -[self.callCard.started timeIntervalSinceNow];
    int seconds = secondsElapsed % 60;
    int minutes = secondsElapsed / 60;
    self.elapsedTimeLabel.text = [NSString stringWithFormat:kJCCallCardCollectionViewCellTimerFormat, minutes, seconds];
}

-(void)holdTimerUpdate
{
    int secondsElapsed = -[self.callCard.holdStarted timeIntervalSinceNow];
    int seconds = secondsElapsed % 60;
    int minutes = secondsElapsed / 60;
    self.holdElapsedTimeLabel.text = [NSString stringWithFormat:kJCCallCardCollectionViewCellTimerFormat, minutes, seconds];
}

-(void)updateState:(BOOL)animated
{
    if (_holdTimer)
    {
        [_holdTimer invalidate];
        _holdTimer = nil;
    }
    
    if (self.callCard.hold) {
        [self showHoldStateAnimated:animated];
    }
    else {
        [self showConnectedState:animated];
    }
    
    if ([self.callCard isKindOfClass:[JCConferenceCallCard class]])
    {
        [self showHoldButton:YES];
        [self startTimer];
    }
    else
    {
        switch (self.callCard.lineSession.sessionState)
        {
            case JCCallFailed:
            case JCCallCanceled:
            {
                [self hideHoldButton:NO];
                self.elapsedTimeLabel.text = NSLocalizedString(@"CANCELED", nil);
                break;
            }
            case JCCallConnected:
            {
                [self showHoldButton:YES];
                [self startTimer];
                break;
            }
            default:
                [self hideHoldButton:NO];
                self.elapsedTimeLabel.text = NSLocalizedString(@"RINGING", nil);
                break;
        }
    }
}


/**
 * Animates up the hold view and sets the actions background to be shown. Whole view is fully visible. The hold button
 * should be visible.
 */
-(void)showConnectedState:(bool)animated
{
    // @!^$#$ Apple! Seriously!
    if ([[UIDevice currentDevice].systemVersion floatValue] < 8.0f)
    {
        _cardInfoViewTopConstraint.constant = -15;
        _holdViewTopConstraint.constant = -5;
    }
    else
    {
        _cardInfoViewTopConstraint.constant = -28;
        _holdViewTopConstraint.constant = -10;
    }
    
    
    self.endCallButton.selected = false;
    [_cardInfoView setNeedsUpdateConstraints];
    
    if ([_holdCallButton.layer animationForKey:kJCCallCardCollectionViewCellHoldButtonPulseAnimationKey])
        [_holdCallButton.layer removeAnimationForKey:kJCCallCardCollectionViewCellHoldButtonPulseAnimationKey];
    
    __unsafe_unretained JCCurrentCallCardViewCell *weakSelf = self;
    __block void (^holdAnimation)() = [^void(){
        weakSelf.layer.borderWidth = CALL_CARD_BORDER_WIDTH;
        _cardInfoView.alpha = 1;
        [_cardInfoView layoutIfNeeded];
        weakSelf.actionView.backgroundColor = _defaultCallActionsColor;
        weakSelf.highlighted = false;
        weakSelf.endCallButton.alpha = 1;
    } copy];
    
    if (animated)
    {
        [UIView animateWithDuration:_holdAnimationDuration
                              delay:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             holdAnimation();
                         }
                         completion:NULL];
    }
    else
    {
        holdAnimation();
    }
}

/**
 * Animates down the hold view, and fades the action background to be clear. Partially fades the whole view. The hold
 * button should be visible.
 */
-(void)showHoldStateAnimated:(BOOL)animated
{
    // @!^$#$ Apple! Seriously!
    if ([[UIDevice currentDevice].systemVersion floatValue] < 8.0f)
    {
        _cardInfoViewTopConstraint.constant = 13;
        _holdViewTopConstraint.constant = 5;
    }
    else
    {
        _cardInfoViewTopConstraint.constant = 0;
        _holdViewTopConstraint.constant = 0;
    }
    self.endCallButton.selected = true;
    [_cardInfoView setNeedsUpdateConstraints];
    
    _holdTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(holdTimerUpdate) userInfo:nil repeats:YES];
    [self holdTimerUpdate];
    
    __unsafe_unretained JCCurrentCallCardViewCell *weakSelf = self;
    __block void (^holdAnimation)() = [^void(){
        weakSelf.layer.borderWidth = 0;
        _cardInfoView.alpha = _holdAnimationAlpha;
        [_cardInfoView layoutIfNeeded];
        weakSelf.actionView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.35/2];
        weakSelf.highlighted = true;
        weakSelf.endCallButton.alpha = HOLD_PULSE_OPACITY_TO_VALUE;
    } copy];
    
    if (animated)
    {
        [UIView animateWithDuration:_holdAnimationDuration
                              delay:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             holdAnimation();
                         }
                         completion:NULL];
        
        
        CALayer *holdBtnLayer = _holdCallButton.layer;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
            
            CABasicAnimation *pulseAnim = [CABasicAnimation animationWithKeyPath:@"opacity"];
            pulseAnim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
            pulseAnim.fromValue = @1.0f;
            pulseAnim.toValue = @HOLD_PULSE_OPACITY_TO_VALUE;
            pulseAnim.repeatCount = INFINITY;
            pulseAnim.duration = _holdPulseAnimationDuration;
            pulseAnim.autoreverses = YES;
            pulseAnim.removedOnCompletion = NO;
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                [holdBtnLayer addAnimation:pulseAnim forKey:kJCCallCardCollectionViewCellHoldButtonPulseAnimationKey];
            });
        });
    }
    else
    {
        holdAnimation();
    }
}

-(void)hideHoldButton:(bool)animated
{
    _endCallButtonWidthConstraint.constant = self.bounds.size.width;
    [_actionView setNeedsUpdateConstraints];
    [UIView animateWithDuration:animated ? 0.3 : 0
                     animations:^{
                         [_actionView layoutIfNeeded];
                     } completion:^(BOOL finished) {
                         _showingHold = false;
                     }];
}

-(void)showHoldButton:(bool)animated
{
    _endCallButtonWidthConstraint.constant = _originalEndCallButtonWidthConstraint;
    [_actionView setNeedsUpdateConstraints];
    
    [UIView animateWithDuration:animated ? 0.3 : 0
                     animations:^{
                         [_actionView layoutIfNeeded];
                     } completion:^(BOOL finished) {
                         _showingHold = true;
                     }];
}

@end
