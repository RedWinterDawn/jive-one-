//
//  JCLoginViewController.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 4/11/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCLoginViewController.h"
#import "JCAuthenticationManager.h"
#import "UITextField+ELFixSecureTextFieldFont.h"

#import "UIViewController+HUD.h"

@interface JCLoginViewController () <NSFileManagerDelegate>
{
    JCAuthenticationManager *_authenticationManager;
}
@end

@implementation JCLoginViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.passwordTextField fixSecureTextFieldFont];
    
    _authenticationManager = [JCAuthenticationManager sharedInstance];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(authenticated:) name:kJCAuthenticationManagerUserAuthenticatedNotification object:_authenticationManager];
    
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
    
    
    self.rememberMeSwitch.on = _authenticationManager.rememberMe;
    if (_authenticationManager.rememberMe) {
        self.usernameTextField.text = _authenticationManager.rememberMeUser;
        [self.passwordTextField becomeFirstResponder];
    } else {
#if DEBUG
        self.usernameTextField.text = @"jivetesting@gmail.com";
        self.passwordTextField.text = @"testing12";
#endif
        [self.usernameTextField becomeFirstResponder];
    }
    
    [Flurry logEvent:@"Login View"];
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
        _authenticationManager.rememberMe = ((UISwitch *)sender).on;
    }
}

#pragma mark - Private - 

- (void)login
{
    [self showHudWithTitle:@"One Moment Please"
                    detail:@"Logging In"];
    
    [_authenticationManager loginWithUsername:self.usernameTextField.text
                                     password:self.passwordTextField.text
                                    completed:^(BOOL success, NSError *error) {
                                        [self hideHud];
                                        if (error) {
                                            [self showSimpleAlert:error.localizedFailureReason
                                                          message:error.localizedDescription];
                                        }
                                    }];
}

#pragma mark - Notification Handlers -

- (void)authenticated:(NSNotification *)notification
{
    [self showHudWithTitle:@"One Moment Please"
                    detail:@"Loading data"];
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
