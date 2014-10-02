//
//  JCDialerOptions.h
//  JiveOne
//
//  Created by P Leonard on 9/30/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JCRoundedButton.h"

@class JCRoundedButton;

typedef enum : NSUInteger {
    JCDialerOptionSingle = 0,
    JCDialerOptionMultiple,
    JCDialerOptionConference,
} JCDialerOptionState;

@interface JCDialerOptions : UIView

@property (nonatomic) JCDialerOptionState state;

@property (nonatomic, weak) IBOutlet UIButton *transferBtn;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *transferBtnHorizontalContstraint;

@property (nonatomic, weak) IBOutlet UIButton *warmTransferBtn;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *warmBtnVerticalConstraint;

@property (nonatomic, weak) IBOutlet UIButton *addCallBtn;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *addCallBtnHorizontalContstraint;

@property (nonatomic, weak) IBOutlet UIButton *swapBtn;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *swapBtnHorizontalContstraint;

@property (nonatomic, weak) IBOutlet UIButton *mergeBtn;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *mergeBtnHorizontalContstraint;

-(void)setState:(JCDialerOptionState)state animated:(bool)animated;

@end
