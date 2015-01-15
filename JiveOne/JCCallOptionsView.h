//
//  JCDialerOptions.h
//  JiveOne
//
//  Created by P Leonard on 9/30/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    JCCallOptionsViewInitalCallState = 0,
    JCCallOptionViewSingleCallState,
    JCCallOptionViewMultipleCallsState,
    JCCallOptionViewConferenceCallState,
    JCCallOptionViewFinishTransferState
} JCCallOptionViewState;

@interface JCCallOptionsView : UIView

@property (nonatomic) JCCallOptionViewState state;
@property (nonatomic) CGFloat annimationDuration;

@property (nonatomic, weak) IBOutlet NSLayoutConstraint *callOptionsYConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *bottomSpaceToOptionsViewConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *transferBtnHorizontalContstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *warmBtnVerticalConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *addCallBtnHorizontalContstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *swapBtnHorizontalContstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *mergeBtnHorizontalContstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *finishTransferConstraint;

-(void)setState:(JCCallOptionViewState)state animated:(bool)animated;

@end
