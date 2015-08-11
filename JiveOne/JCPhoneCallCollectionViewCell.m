//
//  JCCallCard.m
//  JiveOne
//
//  Created by P Leonard on 9/30/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCPhoneCallCollectionViewCell.h"
#import "NSString+Additions.h"

@implementation JCPhoneCallCollectionViewCell

-(void)awakeFromNib
{
    self.layer.borderColor      = CALL_CARD_BORDER_COLOR.CGColor;
    self.layer.borderWidth      = CALL_CARD_BORDER_WIDTH;
    self.layer.cornerRadius     = CALL_CARD_CORNER_RADIUS;
    self.layer.masksToBounds    = TRUE;
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    self.nameLabel.text     = _callCard.callerId;
    self.numberLabel.text   = _callCard.dialNumber;
}

#pragma mark - Setters -

-(void)setCallCard:(JCPhoneCall *)callCard
{
    _callCard = callCard;
    [self setNeedsLayout];
}

-(void)setHighlighted:(BOOL)highlighted
{
    // Override to disable default action
}

-(void)setSelected:(BOOL)selected
{
    // Overide to disable default action.
}

/**
 * Due to an iOS 7 bug under the iOS 8 SDK, it appear that the content's view bounds is not updated 
 * when the cell's bounds are changed via the Autolayout feature, causing some odd behavior when 
 * running the app in iOS7. Here for backwards compatibility with iOS 7. - Robert Barclay, Oct 2014.
 */
- (void)setBounds:(CGRect)bounds
{
    [super setBounds:bounds];
    
    if (!([[UIDevice currentDevice].systemVersion floatValue] < 8.0f))
        self.contentView.frame = bounds;
}

#pragma mark - IBActions -

-(IBAction)hangup:(id)sender
{
    if ([sender isKindOfClass:[UIButton class]]) {
        UIButton *button = (UIButton *)sender;
        button.enabled = false;
        [_callCard endCall:^(BOOL success, NSError *error) {
            button.enabled = true;
        }];
    }
}

-(IBAction)answer:(id)sender
{
    if ([sender isKindOfClass:[UIButton class]]) {
        UIButton *button = (UIButton *)sender;
        button.enabled = false;
        [_callCard answerCall:^(BOOL success, NSError *error) {
            button.enabled = true;
        }];
    }
}

@end