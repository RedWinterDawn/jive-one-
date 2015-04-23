//
//  JCCallerViewController.h
//  JiveOne
//
//  Created by Robert Barclay on 9/30/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

@import UIKit;

#import "JCCallOptionsView.h"
#import "JCLineSession.h"

@interface JCCallerViewController : UIViewController

@property (weak, nonatomic) IBOutlet JCCallOptionsView *callOptionsView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *callOptionsViewOriginYConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *callCardCollectionViewOriginYConstraint;
@property (weak, nonatomic) IBOutlet UIButton *muteBtn;
@property (weak, nonatomic) IBOutlet UIButton *speakerBtn;
@property (weak, nonatomic) IBOutlet UILabel *mergeLabel;
@property (weak, nonatomic) IBOutlet UIButton *keypadButton;
@property (weak, nonatomic) IBOutlet UIButton *blindTransfer;
@property (weak, nonatomic) IBOutlet UIButton *swapBtn;
@property (weak, nonatomic) IBOutlet UIButton *mergeBtn;
@property (weak, nonatomic) IBOutlet UIButton *warmTransfer;
@property (weak, nonatomic) IBOutlet UIButton *addBtn;
@property (weak, nonatomic) IBOutlet UIButton *finishTransferBtn;

@property (nonatomic) BOOL callOptionsHidden;
@property (nonatomic) NSTimeInterval callOptionTransitionAnimationDuration;
@property (nonatomic) NSTimeInterval transferAnimationDuration;
@property (nonatomic) NSTimeInterval keyboardAnimationDuration;

-(void)startConferenceCall;
-(void)stopConferenceCall;
-(void)reload;

// IBActions to trigger events with the call.
-(IBAction)speaker:(id)sender;
-(IBAction)keypad:(id)sender;
-(IBAction)mute:(id)sender;
-(IBAction)blindTransfer:(id)sender;
-(IBAction)warmTransfer:(id)sender;
-(IBAction)addCall:(id)sender;
-(IBAction)swapCall:(id)sender;
-(IBAction)mergeCall:(id)sender;
-(IBAction)finishTransfer:(id)sender;

@end
