//
//  JCLoginViewController.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 4/11/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JCLoginViewController : UIViewController <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UILabel *loginStatusLabel;
@property (nonatomic) BOOL seenTutorial;
@property (nonatomic) BOOL doneLoadingContent;
@property (nonatomic) BOOL userIsDoneWithTutorial;

- (IBAction)termsAndConditionsButton:(id)sender;

@end
