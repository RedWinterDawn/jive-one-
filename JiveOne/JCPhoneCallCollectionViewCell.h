//
//  JCCallCard.h
//  JiveOne
//
//  Created by P Leonard on 9/30/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

@import UIKit;

#import "JCPhoneCall.h"

#define CALL_CARD_BORDER_WIDTH 0.5f
#define CALL_CARD_BORDER_COLOR [UIColor colorWithWhite:1 alpha:0.6]
#define CALL_CARD_CORNER_RADIUS 2

@interface JCPhoneCallCollectionViewCell : UICollectionViewCell
{
    JCPhoneCall *_callCard;
}

@property (nonatomic, strong) JCPhoneCall *callCard;

// Subviews
@property (nonatomic, weak) IBOutlet UILabel *nameLabel;
@property (nonatomic, weak) IBOutlet UILabel *numberLabel;
@property (nonatomic, weak) IBOutlet UIButton *endCallButton;
@property (nonatomic, weak) IBOutlet UIButton *answerCallButton;

// Actions
-(IBAction)hangup:(id)sender;
-(IBAction)answer:(id)sender;

@end