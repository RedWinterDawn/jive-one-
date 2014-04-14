//
//  JCLoginViewController.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 4/11/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCLoginViewController.h"
#import "JCAuthenticationManager.h"
#import "JCAppDelegate.h"

@interface JCLoginViewController ()

@end

@implementation JCLoginViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshAuthenticationCredentials:) name:kAuthenticationFromTokenFailed object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tokenValidityPassed:) name:kAuthenticationFromTokenSucceeded object:nil];
    
    _usernameTextField.returnKeyType = UIReturnKeyNext;
    _passwordTextField.returnKeyType = UIReturnKeyGo;
    
    _usernameTextField.delegate = self;
    _passwordTextField.delegate = self;
    
    
    NSString* fontName = @"Avenir-Book";
    NSString* boldFontName = @"Avenir-Black";
    
    _usernameTextField.backgroundColor = [UIColor whiteColor];
    _usernameTextField.placeholder = @"Email Address";
    _usernameTextField.font = [UIFont fontWithName:fontName size:16.0f];
    _usernameTextField.layer.borderColor = [UIColor colorWithWhite:0.9 alpha:0.7].CGColor;
    _usernameTextField.layer.borderWidth = 1.0f;
    
    UIView* leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 41, 20)];
    _usernameTextField.leftViewMode = UITextFieldViewModeAlways;
    _usernameTextField.leftView = leftView;
    
    _passwordTextField.backgroundColor = [UIColor whiteColor];
    _passwordTextField.placeholder = @"Password";
    _passwordTextField.font = [UIFont fontWithName:fontName size:16.0f];
    _passwordTextField.layer.borderColor = [UIColor colorWithWhite:0.9 alpha:0.7].CGColor;
    _passwordTextField.layer.borderWidth = 1.0f;
    
    UIView* leftView2 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 41, 20)];
    _passwordTextField.leftViewMode = UITextFieldViewModeAlways;
    _passwordTextField.leftView = leftView2;
    
    _loginStatusLabel.font = [UIFont fontWithName:boldFontName size:16.0f];
    // Do any additional setup after loading the view.
}

- (void)viewDidDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kAuthenticationFromTokenFailed object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kAuthenticationFromTokenSucceeded object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == _usernameTextField) {
        [_passwordTextField becomeFirstResponder];
        return NO;
    }
    else {
        [self validateFields];
        [_passwordTextField resignFirstResponder];
        return YES;
    }
}

- (void)validateFields
{
    if([_usernameTextField.text length] != 0 && [_passwordTextField.text length] != 0)
    {
        [[JCAuthenticationManager sharedInstance] loginWithUsername:_usernameTextField.text password:_passwordTextField.text];
    }
    else
    {
        [self alertStatus:@"Invalid Parameters" message:@"UserName/Password Cannot Be Empty"];
    }
}

-(void)alertStatus:(NSString*)title message:(NSString*)message
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    
    
    [alert show];
}

- (void)refreshAuthenticationCredentials:(NSNotification*)notification
{
    _loginStatusLabel.text = NSLocalizedString(@"Invalid username/password", @"Invalid username/password");
    _loginStatusLabel.hidden = NO;
}

- (void)tokenValidityPassed:(NSNotification*)notification
{
    JCAppDelegate *delegate = (JCAppDelegate *)[UIApplication sharedApplication].delegate;
    [delegate changeRootViewController:JCRootTabbarViewController];
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
