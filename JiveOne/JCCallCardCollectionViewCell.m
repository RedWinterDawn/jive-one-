//
//  JCCallCard.m
//  JiveOne
//
//  Created by P Leonard on 9/30/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCCallCardCollectionViewCell.h"
#import "JCCallCardManager.h"
#import "NSString+IsNumeric.h"

#define HOLD_ANIMATION_DURATION 0.5f
#define HOLD_ANIMATION_ALPHA 0.5f
#define HOLD_PULSE_ANIMATION_DURATION 1.0f
#define HOLD_PULSE_OPACITY_TO_VALUE 0.35f

NSString *const kJCCallCardCollectionViewCellTimerFormat = @"%02d:%02d";
NSString *const kJCCallCardCollectionViewCellHoldButtonPulseAnimationKey = @"pulse";

@interface JCCallCardCollectionViewCell()
{
    NSTimer *_timer;
    NSTimer *_holdTimer;
    UIColor *_defaultCallActionsColor;
    CGFloat _currentCallCardInfoElevation;
    CGFloat _originalCurrentCallViewConstraint;
    CGFloat _originalEndCallButtonWidthConstraint;
    
    bool _showingHold;
}
@end

@implementation JCCallCardCollectionViewCell

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
    _defaultCallActionsColor                = self.callActions.backgroundColor;
    _currentCallCardInfoElevation           = self.callCardInfoTopConstraint.constant;
    _originalCurrentCallViewConstraint      = self.currentCallTopToContainerConstraint.constant;
    _originalEndCallButtonWidthConstraint   = self.endCallButtonWidthConstraint.constant;
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    self.callerIdLabel.text             = _callCard.callerId;
    NSString *dialNumber                = _callCard.dialNumber;
    if (dialNumber.isNumeric)
    {
        self.dialedNumberLabel.dialString = dialNumber;
    }
    else
    {
        self.dialedNumberLabel.text = dialNumber;
    }
    
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqualToString:kJCCallCardHoldKey] && self.superview != nil)
    {
        [self updateHoldState];
    }
	else if ([keyPath isEqualToString:kJCCallCardStatusChangeKey])
    {
		switch (_callCard.lineSession.mCallState)
        {
			case JCNoCall:
				self.elapsedTimeLabel.text = NSLocalizedString(@"CONNECTING", nil);
                [self hideHoldButton:NO];
				break;
			case JCCallFailed:
			case JCCallCanceled:
				self.elapsedTimeLabel.text = NSLocalizedString(@"CANCELED", nil);
                [self hideHoldButton:NO];
				break;
			case JCCallRinging:
				self.elapsedTimeLabel.text = NSLocalizedString(@"RINGING", nil);
                [self hideHoldButton:NO];
				break;
			case JCCallConnected:
                [self showHoldButton:YES];
                if (!_timer) {
					_timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(timerUpdate) userInfo:nil repeats:YES];
					[self timerUpdate];
				}
				break;
            default:
                break;
		}
	}
}

-(void)dealloc
{
    if (_callCard != nil)
    {
        [_callCard removeObserver:self forKeyPath:kJCCallCardHoldKey];
        [_callCard removeObserver:self forKeyPath:kJCCallCardStatusChangeKey];
    }
}

#pragma mark - Setters -

-(void)setCallCard:(JCCallCard *)callCard
{
	if (_callCard) {
        [_callCard removeObserver:self forKeyPath:kJCCallCardHoldKey];
		[_callCard removeObserver:self forKeyPath:kJCCallCardStatusChangeKey];
	}
	
    _callCard = callCard;
    if (callCard != nil)
    {
        [callCard addObserver:self forKeyPath:kJCCallCardHoldKey options:NSKeyValueObservingOptionNew context:NULL];
        [callCard addObserver:self forKeyPath:kJCCallCardStatusChangeKey options:NSKeyValueObservingOptionInitial context:NULL];
    }
    
    [self setNeedsLayout];
}

/**
 * Due to an iOS 7 bug under the iOS 8 SDK, it appear that the content's view bounds is not updated when the cell's 
 * bounds are changed via the Autolayout feature, causing some odd behavior when running the app in iOS7. Here for 
 * backwards compatibility with iOS 7. - Robert Barclay, Oct 2014.
 */
- (void)setBounds:(CGRect)bounds
{
    [super setBounds:bounds];
    
    if ([[UIDevice currentDevice].systemVersion floatValue] < 8.0f)
        self.contentView.frame = bounds;
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
    self.elapsedTimeLabel.text = [NSString stringWithFormat:kJCCallCardCollectionViewCellTimerFormat, minutes, seconds];
}

-(void)holdTimerUpdate
{
    int secondsElapsed = -[_callCard.holdStarted timeIntervalSinceNow];
    int seconds = secondsElapsed % 60;
    int minutes = secondsElapsed / 60;
    self.holdElapsedTimeLabel.text = [NSString stringWithFormat:kJCCallCardCollectionViewCellTimerFormat, minutes, seconds];
}

-(void)updateHoldState
{
    if (_holdTimer)
    {
        [_holdTimer invalidate];
        _holdTimer = nil;
    }
    
    if (_callCard.hold) {
        [self showHoldStateAnimated:YES];
    }
    else {
        [self showConnectedState:YES];
    }
}

/**
 * Animates up the hold view and sets the actions background to be shown. Whole view is fully visible. The hold button 
 * should be visible.
 */
-(void)showConnectedState:(bool)animated
{
    __unsafe_unretained JCCallCardCollectionViewCell *weakSelf = self;
    _currentCallTopToContainerConstraint.constant = _originalCurrentCallViewConstraint;
    _callCardInfoTopConstraint.constant = _currentCallCardInfoElevation;
    [_cardInfoView setNeedsUpdateConstraints];
    
    if ([_holdCallButton.layer animationForKey:kJCCallCardCollectionViewCellHoldButtonPulseAnimationKey])
        [_holdCallButton.layer removeAnimationForKey:kJCCallCardCollectionViewCellHoldButtonPulseAnimationKey];
    
    [UIView animateWithDuration:(animated ? _holdAnimationDuration : 0)
                     animations:^{
                         weakSelf.alpha = 1;
                         weakSelf.callActions.backgroundColor = _defaultCallActionsColor;
                         [_cardInfoView layoutIfNeeded];
                     }];
}

/**
 * Animates down the hold view, and fades the action background to be clear. Partially fades the whole view. The hold 
 * button should be visible.
 */
-(void)showHoldStateAnimated:(BOOL)animated
{
    __unsafe_unretained JCCallCardCollectionViewCell *weakSelf = self;
    _currentCallTopToContainerConstraint.constant = 10;
    _callCardInfoTopConstraint.constant = 40;
    [_cardInfoView setNeedsUpdateConstraints];
        
    _holdTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(holdTimerUpdate) userInfo:nil repeats:YES];
    [self holdTimerUpdate];
        
    [UIView animateWithDuration:(animated ? _holdAnimationDuration : 0)
                         animations:^{
                             weakSelf.alpha = _holdAnimationAlpha;
                             weakSelf.callActions.backgroundColor = [UIColor clearColor];
                             [_cardInfoView layoutIfNeeded];
                         }];
    
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

-(void)hideHoldButton:(bool)animated
{
    _endCallButtonWidthConstraint.constant = self.bounds.size.width;
    [_callActions setNeedsUpdateConstraints];
    
    [UIView animateWithDuration:animated ? 0.3 : 0
                     animations:^{
                         [_callActions layoutIfNeeded];
                     } completion:^(BOOL finished) {
                         _showingHold = false;
                     }];
}

-(void)showHoldButton:(bool)animated
{
    _endCallButtonWidthConstraint.constant = _originalEndCallButtonWidthConstraint;
    [_callActions setNeedsUpdateConstraints];
    
    [UIView animateWithDuration:animated ? 0.3 : 0
                     animations:^{
                         [_callActions layoutIfNeeded];
                     } completion:^(BOOL finished) {
                         _showingHold = true;
                     }];
}

@end