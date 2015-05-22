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
#import "JCCallOptionsView.h"
#define HOLD_ANIMATION_DURATION 0.5f
#define HOLD_ANIMATION_ALPHA 0.6f
#define HOLD_PULSE_ANIMATION_DURATION 1.0f
#define HOLD_PULSE_OPACITY_TO_VALUE 0.35f

NSString *const kJCCallCardCollectionViewCellHoldButtonPulseAnimationKey = @"pulse";
NSString *const kJCCallCardCollectionViewCellTimerFormat = @"%02d:%02d";

@interface JCCurrentCallCardViewCell ()
{
    UIColor *_defaultCallActionsColor;
    CGFloat _currentCallCardInfoElevation;
    CGFloat _originalCurrentCallViewConstraint;
    CGFloat _originalEndCallButtonWidthConstraint;
    
    NSTimer *_timer;
    
    BOOL _showingHold;
}

@end

@implementation JCCurrentCallCardViewCell

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        _holdAnimationDuration      = HOLD_ANIMATION_DURATION;
        _holdAnimationAlpha         = HOLD_ANIMATION_ALPHA;
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

-(void)prepareForReuse
{
    [super prepareForReuse];
    
    // Dispose of the timers
    if (_holdTimer) {
        [_holdTimer invalidate];
        _holdTimer = nil;
    }
    
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
    }
    
    [self removeObservers];
}

-(void)dealloc
{
    [self removeObservers];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:kJCLineSessionStateKey] || [keyPath isEqualToString:kJCLineSessionHoldKey]){
        [self updateState:YES];
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
    if ([sender isKindOfClass:[UIButton class]]) {
        UIButton *button = (UIButton *)sender;
        button.enabled = FALSE;
        if (_callCard.lineSession.isHolding) {
            [_callCard unholdCall:^(BOOL success, NSError *error) {
                button.enabled = TRUE;
            }];
        }
        else {
            [_callCard holdCall:^(BOOL success, NSError *error) {
                button.enabled = TRUE;
            }];
        }
    }
}

#pragma mark - Setters -

-(void)setCallCard:(JCCallCard *)callCard
{
    [super setCallCard:callCard];
    [self updateState:NO];
    if (_callCard.lineSession) {
        [_callCard.lineSession addObserver:self forKeyPath:kJCLineSessionStateKey options:0 context:NULL];
        [_callCard.lineSession addObserver:self forKeyPath:kJCLineSessionHoldKey options:0 context:NULL];
    }
}

-(void)setHolding:(BOOL)holding
{
    [self setHolding:holding animated:YES];
}

-(void)setHolding:(BOOL)holding animated:(BOOL)animated
{
    if (holding) {
        [self showHoldStateAnimated:animated];
    }
    else {
        [self showConnectedState:animated];
    }
}

#pragma mark - Private -

-(void)removeObservers
{
    if (_callCard) {
        @try {
            if (_callCard.lineSession) {
                [_callCard.lineSession removeObserver:self forKeyPath:kJCLineSessionStateKey];
                [_callCard.lineSession removeObserver:self forKeyPath:kJCLineSessionHoldKey];
            }
        }
        @catch (NSException *exception) {
            
        }
    }
}

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
    
    [self setHolding:_callCard.lineSession.isHolding animated:animated];
    switch (_callCard.lineSession.sessionState)
    {
        case JCCallFailed:
        case JCCallCanceled:
        {
            [self hideHoldButton:NO];
            self.elapsedTimeLabel.text = NSLocalizedStringFromTable(@"CANCELED", @"Phone", @"Call Status Display");
            break;
        }
        case JCCallConnected:
        {
            [self showHoldButton:YES];
            [self startTimer];
            break;
        }
        case JCNoCall:
        case JCCallInitiated:
        case JCCallIncoming:
        case JCCallTrying:
        case JCCallProgress:
        case JCCallRinging:
        case JCCallAnswered:
            [self hideHoldButton:NO];
            self.elapsedTimeLabel.text = NSLocalizedStringFromTable(@"RINGING", @"Phone", @"Call Status Display");
            break;
        default:
            break;
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
        _cardInfoViewTopConstraint.constant = -35;
        _holdViewTopConstraint.constant = 0;
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
        weakSelf.endCallButton.alpha = 1;
        weakSelf.elapsedTimeLabel.highlighted = NO;
        weakSelf.nameLabel.highlighted = NO;
        weakSelf.numberLabel.highlighted = NO;
    } copy];
    
    if (animated)
    {
        [UIView animateWithDuration:_holdAnimationDuration
                              delay:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             holdAnimation();
                         }
                         completion:^(BOOL finished) {
                             
                         }];
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
        _cardInfoViewTopConstraint.constant = 0;
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
        weakSelf.endCallButton.alpha = HOLD_PULSE_OPACITY_TO_VALUE;
        weakSelf.elapsedTimeLabel.highlighted = YES;
        weakSelf.nameLabel.highlighted = YES;
        weakSelf.numberLabel.highlighted = YES;
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
    if(!_showingHold)
        return;
    
    _endCallButtonWidthConstraint.constant = (self.bounds.size.width / 2);
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
    if(_showingHold)
        return;
    
    _endCallButtonWidthConstraint.constant = (self.bounds.size.width / 2);
    [_actionView setNeedsUpdateConstraints];
    
    [UIView animateWithDuration:animated ? 0.3 : 0
                     animations:^{
                         [_actionView layoutIfNeeded];
                     } completion:^(BOOL finished) {
                         _showingHold = true;
                     }];
}

@end
