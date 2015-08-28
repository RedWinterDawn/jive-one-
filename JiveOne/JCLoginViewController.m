//
//  JCLoginViewController.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 4/11/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCLoginViewController.h"
#import "JCUserManager.h"
#import "UITextField+ELFixSecureTextFieldFont.h"

#import <JCPhoneModule/JCProgressHUD.h>
#import <JCPhoneModule/JCAlertView.h>

@interface JCLoginViewController () <NSFileManagerDelegate>

@end

@implementation JCLoginViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.loginPromptVisualEffectsView.backgroundView        = self.navigationController.view;
    self.termsAndConditionsVisualEffectsView.backgroundView = self.navigationController.view;
    
    [self.passwordTextField fixSecureTextFieldFont];
    
    JCUserManager *authenticationManager = self.userManager;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(authenticated:) name:kJCAuthenticationManagerUserAuthenticatedNotification object:authenticationManager];
    
    self.usernameTextField.layer.borderColor = [UIColor colorWithWhite:0.9 alpha:0.7].CGColor;
    self.usernameTextField.layer.borderWidth = 1.0f;
    
    self.usernameTextField.leftViewMode = UITextFieldViewModeAlways;
    self.usernameTextField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 20)];
    
    self.passwordTextField.layer.borderColor = [UIColor colorWithWhite:0.9 alpha:0.7].CGColor;
    self.passwordTextField.layer.borderWidth = 1.0f;
    
    self.passwordTextField.layer.cornerRadius = 5;
    self.passwordTextField.layer.masksToBounds = YES;
    self.usernameTextField.layer.cornerRadius = 5;
    self.usernameTextField.layer.masksToBounds = YES;
    
    self.passwordTextField.leftViewMode = UITextFieldViewModeAlways;
    self.passwordTextField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 20)];
    
    JCAuthSettings *settings = authenticationManager.settings;
    self.rememberMeSwitch.on = settings.rememberMe;
    if (settings.rememberMe) {
        self.usernameTextField.text = settings.rememberMeUser;
        [self.passwordTextField becomeFirstResponder];
    } else {
#if DEBUG
        self.usernameTextField.text = @"rbarclay";
        self.passwordTextField.text = @"";
#endif
        [self.usernameTextField becomeFirstResponder];
    }
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    [self.view endEditing:YES];
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - IBActions -

- (IBAction)rememberMe:(id)sender {
    if ([sender isKindOfClass:[UISwitch class]]) {
        self.userManager.settings.rememberMe = ((UISwitch *)sender).on;
    }
}

#pragma mark - Private - 

- (void)login
{
    [self showStatus:@"Logging In"];
    [self.userManager loginWithUsername:self.usernameTextField.text
                                     password:self.passwordTextField.text
                                    completed:^(BOOL success, NSString *userName, NSError *error) {
                                        [self hideStatus];
                                        if (error) {
                                            [JCAlertView alertWithError:error];
                                        }
                                    }];
}

#pragma mark - Notification Handlers -

- (void)authenticated:(NSNotification *)notification
{
    [self showStatus:@"Loading data"];
}

#pragma mark - Delegate Handlers -

#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.usernameTextField) {
        [self.passwordTextField becomeFirstResponder];
        return NO;
    }
    else {
        [self login];
        [self.passwordTextField resignFirstResponder];
        return YES;
    }
}

@end
