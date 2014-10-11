//
//  JCCallCard.h
//  JiveOne
//
//  Created by P Leonard on 9/30/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JCCallCard.h"
#import "JCDialStringLabel.h"

@interface JCCallCardCollectionViewCell : UICollectionViewCell

@property (nonatomic, weak) IBOutlet UIView *callActions;
@property (nonatomic, weak) IBOutlet UIView *cardInfoView;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *currentCallTopToContainerConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *callCardInfoTopConstraint;

@property (nonatomic, weak) IBOutlet UILabel *callerIdLabel;
@property (nonatomic, weak) IBOutlet JCDialStringLabel *dialedNumberLabel;
@property (nonatomic, weak) IBOutlet UILabel *elapsedTimeLabel;
@property (nonatomic, weak) IBOutlet UILabel *holdElapsedTimeLabel;

@property (nonatomic, weak) IBOutlet UIButton *endCallButton;
@property (nonatomic, weak) IBOutlet UIButton *holdCallButton;
@property (nonatomic, weak) IBOutlet UIButton *answerCallButton;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *endCallButtonWidthConstraint;

@property (nonatomic, strong) JCCallCard *callCard;

// Configurable Properties.
@property (nonatomic) CGFloat holdAnimationDuration;
@property (nonatomic) CGFloat holdAnimationAlpha;

-(IBAction)hangup:(id)sender;
-(IBAction)toggleHold:(id)sender;
-(IBAction)answer:(id)sender;

@end