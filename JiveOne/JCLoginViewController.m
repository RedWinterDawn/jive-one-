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
//@peter This hadles when you touch anywhere else on the screen the key board is dismissed.
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    [self.view endEditing:YES];
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
    self.usernameTextField.returnKeyType = UIReturnKeyNext;
    
    self.usernameTextField.returnKeyType = UIReturnKeyNext;
    self.passwordTextField.returnKeyType = UIReturnKeyGo;
    
    self.usernameTextField.delegate = self;
    self.passwordTextField.delegate = self;
    
    
    NSString* fontName = @"Avenir-Book";
    NSString* boldFontName = @"Avenir-Black";
    
    self.usernameTextField.placeholder =  NSLocalizedString(@"Email Address", nil);
    self.usernameTextField.font = [UIFont fontWithName:fontName size:16.0f];
    self.usernameTextField.layer.borderColor = [UIColor colorWithWhite:0.9 alpha:0.7].CGColor;
    self.usernameTextField.layer.borderWidth = 1.0f;
    
    UIView* leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 20)];
    self.usernameTextField.leftViewMode = UITextFieldViewModeAlways;
    self.usernameTextField.leftView = leftView;
    
    self.passwordTextField.placeholder =  NSLocalizedString(@"Password", nil);
    self.passwordTextField.font = [UIFont fontWithName:fontName size:16.0f];
    self.passwordTextField.layer.borderColor = [UIColor colorWithWhite:0.9 alpha:0.7].CGColor;
    self.passwordTextField.layer.borderWidth = 1.0f;
    
    // @Pete Adding rounded corners for the elements on login screen
    self.passwordTextField.layer.cornerRadius = 5;
    self.passwordTextField.layer.masksToBounds = YES;
    self.usernameTextField.layer.cornerRadius = 5;
    self.usernameTextField.layer.masksToBounds = YES;
    self.loginViewContainer.layer.cornerRadius = 5;
    [self.loginViewContainer.layer setCornerRadius:5];
    
    
    
    UIView* leftView2 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 20)];
    self.passwordTextField.leftViewMode = UITextFieldViewModeAlways;
    self.passwordTextField.leftView = leftView2;
    
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
    if (self.view.frame.size.height <= 560){
        
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
    }
    [Flurry logEvent:@"Login View"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.usernameTextField) {
        [self.passwordTextField becomeFirstResponder];
        return NO;
    }
    else {
        [self validateFields];
        [self.passwordTextField resignFirstResponder];
        return YES;
    }
}

- (void)validateFields
{
    self.loginStatusLabel.text = @"";
    if([self.usernameTextField.text length] != 0 && [self.passwordTextField.text length] != 0)
    {
        [self showHudWithTitle:@"One Moment Please" detail:@"Logging In"];
        [[JCAuthenticationManager sharedInstance] loginWithUsername:self.usernameTextField.text password:self.passwordTextField.text completed:^(BOOL success, NSError *error) {
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
        [Flurry logEvent:@"First Login"];
        [self performSegueWithIdentifier: @"AppTutorialSegue" sender: self];
    }
//    else
//    {
//        [self showHudWithTitle:@"One Moment Please" detail:@"Preparing for first use"];
//    }
    
    [self fetchMyEntity];
}

- (void)fetchMyEntity
{
    [self.client RetrieveMyEntitity:^(id JSON, id operation) {
        [self fetchEntities];
    } failure:^(NSError *err, id operation) {
        [self errorInitializingApp:err];
    }];
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
    //This animates the view when the keyboard appears and shifts it up in responce.
    [UIView animateKeyframesWithDuration:0.2 delay:0.0 options:UIViewKeyframeAnimationOptionCalculationModeCubic animations:^{
        CGRect frame = self.loginViewContainer.frame;
        CGRect usernameTextField = self.usernameTextField.frame;
        
        frame.origin.y = (frame.origin.y - kShiftKeyboardTHisMuch);
        
        usernameTextField.origin.y = (usernameTextField.origin.y - kShiftKeyboardTHisMuch);
        
        self.loginViewContainer.frame = frame;
        self.usernameTextField.frame = usernameTextField;
    } completion:^(BOOL finished) {
        
    }];
    
}

- (void)keyboardDidHide:(NSNotification *)notification
{
    //This animates the view when the keyboard disappears and shifts it down in responce.
    [UIView animateKeyframesWithDuration:0.2 delay:0.0 options:UIViewKeyframeAnimationOptionCalculationModeCubic animations:^{
        CGRect frame = self.loginViewContainer.frame;
        CGRect usernameTextField = self.usernameTextField.frame;
        
        frame.origin.y = (frame.origin.y + kShiftKeyboardTHisMuch);
        usernameTextField.origin.y = (usernameTextField.origin.y + kShiftKeyboardTHisMuch);
        self.loginViewContainer.frame = frame;
        self.usernameTextField.frame = usernameTextField;
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
