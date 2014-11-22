//
//  JCLoginViewController.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 4/11/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCLoginViewController.h"
#import "JCAuthenticationManager.h"
#import <MBProgressHUD.h>
#import "UITextField+ELFixSecureTextFieldFont.h"

@interface JCLoginViewController () <NSFileManagerDelegate>
{
    JCAuthenticationManager *_authenticationManager;
    MBProgressHUD *_hud;
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
        self.usernameTextField.text = _authenticationManager.jiveUserId;
    } else {
#if DEBUG
        self.usernameTextField.text = @"jivetesting@gmail.com";
        self.passwordTextField.text = @"testing12";
#endif
        [self.usernameTextField becomeFirstResponder];
    }
    
    [Flurry logEvent:@"Login View"];
}

//@peter This hadles when you touch anywhere else on the screen the key board is dismissed.
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    [self.view endEditing:YES];
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - IBActions -

- (IBAction)rememberMe:(id)sender {
    [[JCAuthenticationManager sharedInstance] setRememberMe:((UISwitch *)sender).on];
}

#pragma mark - Private - 

- (void)login
{
    [self showHudWithTitle:NSLocalizedString(@"One Moment Please", nil)
                    detail:NSLocalizedString(@"Logging In", nil)];
    
    [_authenticationManager loginWithUsername:self.usernameTextField.text
                                     password:self.passwordTextField.text
                                    completed:^(BOOL success, NSError *error) {
                                        [self hideHud];
                                        if (error) {
                                            [self alertStatus:error.localizedFailureReason message:error.localizedDescription];
                                        }
                                    }];
}

- (void)showHudWithTitle:(NSString*)title detail:(NSString*)detail
{
    if (!_hud) {
        _hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        _hud.mode = MBProgressHUDModeIndeterminate;
    }
    
    _hud.labelText = title;
    _hud.detailsLabelText = detail;
    [_hud show:YES];
}

- (void)hideHud
{
    if (_hud) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        [_hud removeFromSuperview];
        _hud = nil;
    }
}

-(void)alertStatus:(NSString*)title message:(NSString*)message
{
    NSLog(@"%@: %@", title, message);
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:message
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil, nil];
    [alert show];
}

#pragma mark - Notification Handlers -

- (void)authenticated:(NSNotification*)notification
{
    [self showHudWithTitle:NSLocalizedString(@"One Moment Please", nil)
                    detail:NSLocalizedString(@"Loading data", nil)];
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
