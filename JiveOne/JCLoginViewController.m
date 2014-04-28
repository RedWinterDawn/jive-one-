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
        [[JCAuthenticationManager sharedInstance] loginWithUsername:_usernameTextField.text password:_passwordTextField.text];
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

- (void)tokenValidityPassed:(NSNotification*)notification
{
    [self showHudWithTitle:@"One Moment Please" detail:@"Preparing for first use"];
    [self fetchEntities];
}

- (void)fetchEntities
{
    [[JCOsgiClient sharedClient] RetrieveClientEntitites:^(id JSON) {
        [self fetchCompany];
    } failure:^(NSError *err) {
        [self errorInitializingApp];
    }];
}

- (void)fetchCompany
{
    NSString* company = [[JCOmniPresence sharedInstance] me].resourceGroupName;
    [[JCOsgiClient sharedClient] RetrieveMyCompany:company:^(id JSON) {
        
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
            [self goToApplication];
         }
        
    } failure:^(NSError *err) {
        NSLog(@"%@", err);
        [self errorInitializingApp];
    }];
}

- (void)fetchPresence
{
    [[JCOsgiClient sharedClient] RetrieveEntitiesPresence:^(BOOL updated) {
        [self fetchConversations];
    } failure:^(NSError *err) {
        [self errorInitializingApp];
    }];
}

- (void)fetchConversations
{
    [[JCOsgiClient sharedClient] RetrieveConversations:^(id JSON) {
        [self fetchVoicemails];
    } failure:^(NSError *err) {
        [self errorInitializingApp];
    }];
}

- (void)fetchVoicemails
{
    [[JCOsgiClient sharedClient] RetrieveVoicemailForEntity:nil success:^(id JSON) {
        
        [self hideHud];
        [self goToApplication];
        
    } failure:^(NSError *err) {
        [self errorInitializingApp];
    }];
}



- (void)goToApplication
{
    JCAppDelegate *delegate = (JCAppDelegate *)[UIApplication sharedApplication].delegate;
    [delegate changeRootViewController:JCRootTabbarViewController];
}

- (void)errorInitializingApp
{
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
    if (hud) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        [hud removeFromSuperview];
        hud = nil;
    }
}


@end
