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
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import "Common.h"
#import "JCOsgiClient.h"
#import "Company.h"
#import <MBProgressHUD.h>

@interface JCLoginViewController ()
{
    BOOL fastConnection;
    MBProgressHUD *hud;
}

@end

@implementation JCLoginViewController

- (void)setClient:(JCOsgiClient *)client
{
    _client = client;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setClient:[JCOsgiClient sharedClient]];
    
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"seenAppTutorial"]) {
        self.userIsDoneWithTutorial = YES;
    }
    else
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkIfLoadingHasFinished:) name:@"AppTutorialDismissed" object:nil];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshAuthenticationCredentials:) name:kAuthenticationFromTokenFailed object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshAuthenticationCredentials:) name:kAuthenticationFromTokenFailedWithTimeout object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tokenValidityPassed:) name:kAuthenticationFromTokenSucceeded object:nil];
    
    _usernameTextField.returnKeyType = UIReturnKeyNext;
    _passwordTextField.returnKeyType = UIReturnKeyGo;
    
    _usernameTextField.delegate = self;
    _passwordTextField.delegate = self;
    
    
    NSString* fontName = @"Avenir-Book";
    NSString* boldFontName = @"Avenir-Black";
    
    _usernameTextField.backgroundColor = [UIColor whiteColor];
    _usernameTextField.placeholder =  NSLocalizedString(@"Email Address", nil);
    _usernameTextField.font = [UIFont fontWithName:fontName size:16.0f];
    _usernameTextField.layer.borderColor = [UIColor colorWithWhite:0.9 alpha:0.7].CGColor;
    _usernameTextField.layer.borderWidth = 1.0f;
    
    UIView* leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 41, 20)];
    _usernameTextField.leftViewMode = UITextFieldViewModeAlways;
    _usernameTextField.leftView = leftView;
    
    _passwordTextField.backgroundColor = [UIColor whiteColor];
    _passwordTextField.placeholder =  NSLocalizedString(@"Password", nil);
    _passwordTextField.font = [UIFont fontWithName:fontName size:16.0f];
    _passwordTextField.layer.borderColor = [UIColor colorWithWhite:0.9 alpha:0.7].CGColor;
    _passwordTextField.layer.borderWidth = 1.0f;
    
    UIView* leftView2 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 41, 20)];
    _passwordTextField.leftViewMode = UITextFieldViewModeAlways;
    _passwordTextField.leftView = leftView2;
    
    _loginStatusLabel.font = [UIFont fontWithName:boldFontName size:16.0f];
    // Do any additional setup after loading the view.
    fastConnection = [Common IsConnectionFast];
    
    
}

- (void)viewDidDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kAuthenticationFromTokenFailed object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kAuthenticationFromTokenFailedWithTimeout object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kAuthenticationFromTokenSucceeded object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kAuthenticationFromTokenFailed object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kAuthenticationFromTokenSucceeded object:nil];
    
}

-(void)viewWillAppear:(BOOL)animated{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
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
    self.loginStatusLabel.text = @"";
    if([_usernameTextField.text length] != 0 && [_passwordTextField.text length] != 0)
    {
        [self showHudWithTitle:@"One Moment Please" detail:@"Logging In"];
        [[JCAuthenticationManager sharedInstance] loginWithUsername:_usernameTextField.text password:_passwordTextField.text completed:^(BOOL success, NSError *error) {
            self.doneLoadingContent = NO;
            if (success) {
                [self tokenValidityPassed:nil];
            }
            else {
                if (error.userInfo[@"error"]) {
                    [self alertStatus:@"Authentication Error" message:error.userInfo[@"error"]];
                    NSLog(@"Authentication error: %@", error);
                    [self hideHud];
                }
                else {
                    [self alertStatus:@"Authentication Error" message:error.localizedDescription];
                     NSLog(@"Authentication error: %@", error);
                    [self hideHud];
                }
            }
            
        }];
    }
    else
    {
        [self alertStatus:NSLocalizedString(@"Invalid Parameters", nil) message: NSLocalizedString(@"UserName/Password Cannot Be Empty", nil)];
    }
}

-(void)alertStatus:(NSString*)title message:(NSString*)message
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    
    
    [alert show];
}

- (void)refreshAuthenticationCredentials:(NSNotification*)notification
{
    [self hideHud];
    
    if (notification.object != nil && [kAuthenticationFromTokenFailedWithTimeout isEqualToString:(NSString *)notification.object]) {
        UIAlertView *alertview = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Login Timeout", nil) message:NSLocalizedString(@"Login could not be completed at this time. Please try again later.", nil) delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
        [alertview show];
    }
    else {
    
        _loginStatusLabel.text = NSLocalizedString(@"Invalid username/password", @"Invalid username/password");
        _loginStatusLabel.hidden = NO;
    }
}

-(BOOL)seenTutorial
{
    return _seenTutorial = [[NSUserDefaults standardUserDefaults] boolForKey:@"seenAppTutorial"];
}

-(BOOL)doneLoadingContent
{
    if (!_doneLoadingContent) {
        _doneLoadingContent = NO;
    }
    return _doneLoadingContent;
}
-(BOOL)userIsDoneWithTutorial
{
    if (!_userIsDoneWithTutorial) {
        _userIsDoneWithTutorial = NO;
    }
    return _userIsDoneWithTutorial;
}

- (void)checkIfLoadingHasFinished:(NSNotification *)notification
{
    self.userIsDoneWithTutorial = YES;
    if ([[notification name] isEqualToString:@"AppTutorialDismissed"])
    {
        NSLog (@"Successfully received the AppTutorialDismissed notification!");
        if (!self.doneLoadingContent) {
            [self showHudWithTitle:@"One Moment Please" detail:@"Preparing for first use"];
        }
        else
        {
            [self goToApplication];
        }
    }
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"seenAppTutorial"]) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"AppTutorialDismissed" object:nil];
    }
    

}

- (void)tokenValidityPassed:(NSNotification*)notification
{
    if (!self.seenTutorial) {
        [self performSegueWithIdentifier: @"AppTutorialSegue" sender: self];
    }
//    else
//    {
//        [self showHudWithTitle:@"One Moment Please" detail:@"Preparing for first use"];
//    }
    
    [self fetchEntities];
}

- (void)fetchEntities
{
    [self.client RetrieveClientEntitites:^(id JSON) {
        [self fetchCompany];
    } failure:^(NSError *err) {
        [self errorInitializingApp:err];
    }];
}

- (void)fetchCompany
{
    NSString* company = [[JCOmniPresence sharedInstance] me].resourceGroupName;
    [self.client RetrieveMyCompany:company:^(id JSON) {
        
        NSManagedObjectContext *localContext = [NSManagedObjectContext MR_contextForCurrentThread];
        Company *company = [Company MR_createInContext:localContext];
        company.lastModified = JSON[@"lastModified"];
        company.pbxId = JSON[@"pbxId"];
        company.timezone = JSON[@"timezone"];
        company.name = JSON[@"name"];
        company.urn = JSON[@"urn"];
        company.companyId = JSON[@"id"];
        
        //[[JCOmniPresence sharedInstance] me].entityCompany = company;
        NSArray *clientEntities = [PersonEntities MR_findAll];
        for (PersonEntities *entity in clientEntities) {
            entity.entityCompany = company;
        }
        
        [localContext MR_saveToPersistentStoreAndWait];
        
        [[JCAuthenticationManager sharedInstance] setUserLoadedMinimumData:YES];
        
        if (fastConnection) {
            [self fetchPresence];
        }
        else {
            [self hideHud];
            if (self.doneLoadingContent && self.userIsDoneWithTutorial) {
                [self goToApplication];
            }
         }
        
    } failure:^(NSError *err) {
        NSLog(@"fetchCompany error: %@", err);
        [self errorInitializingApp:err];
    }];
}

- (void)fetchPresence
{
    [self.client RetrieveEntitiesPresence:^(BOOL updated) {
        [self fetchConversations];
    } failure:^(NSError *err) {
        [self errorInitializingApp:err];
    }];
}

- (void)fetchConversations
{
    [self.client RetrieveConversations:^(id JSON) {
        [self fetchVoicemails];
    } failure:^(NSError *err) {
        [self errorInitializingApp:err];
    }];
}

- (void)fetchVoicemails
{
    [self.client RetrieveVoicemailForEntity:nil success:^(id JSON) {
        
        [self hideHud];
        if (self.userIsDoneWithTutorial) {
            [self goToApplication];
        }
        
    } failure:^(NSError *err) {
        [self errorInitializingApp:err];
    }];
}

- (void)keyboardDidShow:(NSNotification *)notification
{
    [UIView animateKeyframesWithDuration:0.2 delay:0.0 options:UIViewKeyframeAnimationOptionCalculationModeCubic animations:^{
        CGRect frame = self.view.frame;
        frame.origin.y = (frame.origin.y - 60);
        self.view.frame = frame;
    } completion:^(BOOL finished) {
        
    }];
    
}

- (void)keyboardDidHide:(NSNotification *)notification
{
    [UIView animateKeyframesWithDuration:0.2 delay:0.0 options:UIViewKeyframeAnimationOptionCalculationModeCubic animations:^{
        CGRect frame = self.view.frame;
        frame.origin.y = (frame.origin.y + 60);
        self.view.frame = frame;
    } completion:^(BOOL finished) {
        
    }];
}

- (void)goToApplication
{
    [self performSegueWithIdentifier: @"LoginToTabBarSegue" sender: self];
}



- (void)errorInitializingApp:(NSError*)err
{
    NSLog(@"errorInitializingApp: %@",err);
    [self hideHud];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle: NSLocalizedString(@"Server Unavailable", nil) message: NSLocalizedString(@"We could not connect to the server at this time. Please try again", nil) delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
    
    [alert show];
    [[JCAuthenticationManager sharedInstance] logout:self];
}

#pragma mark - HUD Operations
- (void)showHudWithTitle:(NSString*)title detail:(NSString*)detail
{
    if (!hud) {
        hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeIndeterminate;
    }
    
    hud.labelText = title;
    hud.detailsLabelText = detail;
    [hud show:YES];
}

- (void)hideHud
{
    self.doneLoadingContent = YES;
    if (hud) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        [hud removeFromSuperview];
        hud = nil;
    }
}


- (IBAction)termsAndConditionsButton:(id)sender {
    [self performSegueWithIdentifier: @"TCSegue" sender: self];
}

@end
