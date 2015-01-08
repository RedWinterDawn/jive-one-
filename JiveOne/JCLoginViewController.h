//
//  JCLoginViewController.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 4/11/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCVisualEffectsView.h"

@interface JCLoginViewController : UIViewController <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet JCVisualEffectsView *loginPromptVisualEffectsView;
@property (weak, nonatomic) IBOutlet JCVisualEffectsView *termsAndConditionsVisualEffectsView;
@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UISwitch *rememberMeSwitch;

- (IBAction)rememberMe:(id)sender;

@end
