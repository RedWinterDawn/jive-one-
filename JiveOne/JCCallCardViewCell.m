//
//  JCCallCard.m
//  JiveOne
//
//  Created by P Leonard on 9/30/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCCallCardViewCell.h"
#import "JCCallCardManager.h"
#import "NSString+IsNumeric.h"

@implementation JCCallCardViewCell

-(void)awakeFromNib
{
    self.layer.borderColor      = CALL_CARD_BORDER_COLOR.CGColor;
    self.layer.cornerRadius     = 2;
    self.layer.masksToBounds    = TRUE;
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    self.callerIdLabel.text     = _callCard.callerId;
    NSString *dialNumber        = _callCard.dialNumber;
    if (dialNumber.isNumeric)
        self.dialedNumberLabel.dialString = dialNumber;
    else
        self.dialedNumberLabel.text = dialNumber;
}

#pragma mark - Setters -

-(void)setCallCard:(JCCallCard *)callCard
{
    _callCard = callCard;
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

-(void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    
    self.callerIdLabel.highlighted = highlighted;
    self.dialedNumberLabel.highlighted = highlighted;
}

#pragma mark - IBActions -

-(IBAction)hangup:(id)sender
{
    [_callCard endCall];
}

-(IBAction)answer:(id)sender
{
    [_callCard answerCall];
}

@end