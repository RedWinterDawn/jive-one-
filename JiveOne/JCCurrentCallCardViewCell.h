//
//  JCCurrentCallCardViewCell.h
//  JiveOne
//
//  Created by Robert Barclay on 10/16/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCCallCardViewCell.h"

@interface JCCurrentCallCardViewCell : JCCallCardViewCell

// Subviews
@property (nonatomic, weak) IBOutlet UIView *actionView;
@property (nonatomic, weak) IBOutlet UIView *cardInfoView;
@property (nonatomic, weak) IBOutlet UIView *infoView;
@property (nonatomic, weak) IBOutlet UIView *holdView;
@property (nonatomic, weak) IBOutlet UILabel *holdElapsedTimeLabel;
@property (nonatomic, weak) IBOutlet UILabel *elapsedTimeLabel;
@property (nonatomic, weak) IBOutlet UIButton *holdCallButton;

// Autolayout Constraints Outlets used for view animation.
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *holdViewTopConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *cardInfoViewTopConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *endCallButtonWidthConstraint;

// Configurable Properties.
@property (nonatomic) CGFloat holdAnimationDuration;
@property (nonatomic) CGFloat holdAnimationAlpha;
@property (nonatomic) CGFloat holdPulseAnimationDuration;

// Actions
-(IBAction)toggleHold:(id)sender;

@end
