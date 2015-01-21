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

@class JCCallerViewController;

@protocol JCCallerViewControllerDelegate <NSObject>

-(void)shouldDismissCallerViewController:(JCCallerViewController *)viewController;

@end

@protocol JCCallViewControllerDataSource <NSObject>

-(BOOL)callerViewControllerShouldShowCallOptions:(JCCallerViewController *)callerViewController;

@end

@interface JCCallerViewController : UIViewController

@property (weak, nonatomic) IBOutlet id<JCCallerViewControllerDelegate> delegate;
@property (weak, nonatomic) IBOutlet id<JCCallViewControllerDataSource> dataSource;

@property (weak, nonatomic) IBOutlet JCCallOptionsView *callOptionsView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *callOptionsViewOriginYConstraint;
@property (weak, nonatomic) IBOutlet UIButton *speakerBtn;
@property (weak, nonatomic) IBOutlet UILabel *mergeLabel;
@property (weak, nonatomic) IBOutlet UIButton *keypadButton;
@property (weak, nonatomic) IBOutlet UIButton *blindTransfer;
@property (weak, nonatomic) IBOutlet UIButton *swapBtn;
@property (weak, nonatomic) IBOutlet UIButton *mergeBtn;
@property (weak, nonatomic) IBOutlet UIButton *warmTransfer;

@property (nonatomic) BOOL callOptionsHidden;
@property (nonatomic) NSTimeInterval callOptionTransitionAnimationDuration;
@property (nonatomic) NSTimeInterval transferAnimationDuration;
@property (nonatomic) NSTimeInterval keyboardAnimationDuration;

// Phone number to be dialed when the view controller is loads.
@property (nonatomic, strong) NSString *dialString __deprecated;

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
