//
//  JCCallCard.m
//  JiveOne
//
//  Created by P Leonard on 9/30/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCCallCardCollectionViewCell.h"
#import "JCCallCardManager.h"

#define HOLD_ANIMATION_DURATION 0.5f
#define HOLD_ANIMATION_ALPHA 0.5f

NSString *const kJCCallCardCollectionViewCellTimerFormat = @"%02d:%02d";

@interface JCCallCardCollectionViewCell()
{
    NSTimer *_timer;
    NSTimer *_holdTimer;
    UIColor *_defaultCallActionsColor;
    CGFloat _currentCallCardInfoElevation;
    CGFloat _originalCurrentCallViewConstraint;
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
    }
    return self;
}

-(void)awakeFromNib
{
    _defaultCallActionsColor            = self.callActions.backgroundColor;
    _currentCallCardInfoElevation       = self.callCardInfoTopConstraint.constant;
    _originalCurrentCallViewConstraint  = self.currentCallTopToContainerConstraint.constant;
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    self.callerIdLabel.text             = _callCard.callerId;
    self.dialedNumberLabel.dialString   = _callCard.dialNumber;
    self.holdCallButton.selected        = _callCard.hold;
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqualToString:kJCCallCardHoldKey])
        [self showHoldStateAnimated:(self.superview != nil)];
	
	else if ([keyPath isEqualToString:kJCCallCardStatusChangeKey])
    {
		switch (_callCard.lineSession.mCallState)
        {
			case JCNoCall:
				self.elapsedTimeLabel.text = NSLocalizedString(@"CONNECTING", nil);
				break;
			case JCCallFailed:
			case JCCallCanceled:
				self.elapsedTimeLabel.text = NSLocalizedString(@"CANCELED", nil);
				break;
			case JCCallRinging:
				self.elapsedTimeLabel.text = NSLocalizedString(@"RINGING", nil);
				break;
			case JCCallConnected:
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
        [callCard addObserver:self forKeyPath:kJCCallCardHoldKey options:NSKeyValueObservingOptionInitial context:NULL];
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
    }
    else
    {
        [_holdTimer invalidate];
        _holdTimer = nil;
        
        _currentCallTopToContainerConstraint.constant = _originalCurrentCallViewConstraint;
        _callCardInfoTopConstraint.constant = _currentCallCardInfoElevation;
        [_cardInfoView setNeedsUpdateConstraints];
        
        [UIView animateWithDuration:(animated ? _holdAnimationDuration : 0)
                         animations:^{
                             weakSelf.alpha = 1;
                             weakSelf.callActions.backgroundColor = _defaultCallActionsColor;
                             [_cardInfoView layoutIfNeeded];
                         }];
    }
}



@end