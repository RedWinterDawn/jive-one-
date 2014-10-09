//
//  JCCallerViewController.h
//  JiveOne
//
//  Created by Robert Barclay on 9/30/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JCCallOptionsView.h"

@class JCCallerViewController;

@protocol JCCallerViewControllerDelegate <NSObject>

-(void)shouldDismissCallerViewController:(JCCallerViewController *)viewController;

@end

@interface JCCallerViewController : UIViewController

@property (nonatomic, weak) IBOutlet id<JCCallerViewControllerDelegate> delegate;
@property (nonatomic, weak) IBOutlet JCCallOptionsView *callOptionsView;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *callOptionsViewOriginYConstraint;

@property (nonatomic) bool callOptionsHidden;
@property (nonatomic) NSTimeInterval callOptionTransitionAnimationDuration;
@property (nonatomic) NSTimeInterval transferAnimationDuration;
@property (nonatomic) NSTimeInterval keyboardAnimationDuration;

// Phone number to be dialed when the view controller is loads.
@property (nonatomic, strong) NSString *dialString;

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
