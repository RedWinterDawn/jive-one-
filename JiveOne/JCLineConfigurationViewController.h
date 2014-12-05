//
//  JCLineConfigurationViewController.h
//  JiveOne
//
//  Created by P Leonard on 12/1/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

@import UIKit;

@class JCLineConfigurationViewController;

@protocol JCLineConfigurationViewControllerDelegate <NSObject>

-(void)lineConfigurationViewControllerShouldDismiss:(JCLineConfigurationViewController *)controller;

@end

@interface JCLineConfigurationViewController : UIViewController <UIPickerViewDelegate, UIPickerViewDataSource>

@property (weak, nonatomic) IBOutlet id <JCLineConfigurationViewControllerDelegate> delegate;

@property (weak, nonatomic) IBOutlet UISwitch *makeDefaultLineSwitch;
@property (weak, nonatomic) IBOutlet UIView *lineListContainer;
@property (weak, nonatomic) IBOutlet UIButton *lineSelection;
@property (weak, nonatomic) IBOutlet UIPickerView *lineList;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *lineListHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *lineListBottomConstraint;

-(IBAction)close:(id)sender;

@end
