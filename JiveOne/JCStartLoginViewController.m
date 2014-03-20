//
//  JCStartLoginViewController.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 2/13/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCStartLoginViewController.h"
#import "JCAuthenticationManager.h"
#import "JCOsgiClient.h"
#import "ClientEntities.h"
#import "Company.h"
#import "JCVersionTracker.h"
#import <MBProgressHUD/MBProgressHUD.h>
#import "JCAppDelegate.h"

@interface JCStartLoginViewController ()
{
    NSMutableData *receivedData;
    MBProgressHUD *hud;
    NSString* username;
    NSString* password;
    
    int loginAttempts;
}

@end

#if DEBUG
@interface NSURLRequest(Private)
+(void)setAllowsAnyHTTPSCertificate:(BOOL)inAllow forHost:(NSString *)inHost;
@end
#endif

@implementation JCStartLoginViewController

static int MAX_LOGIN_ATTEMPTS = 2;

- (void)viewDidLoad
{
    [super viewDidLoad];
    _authWebview.delegate = self;
    
    _usernameTextField.returnKeyType = UIReturnKeyNext;
    _passwordTextField.returnKeyType = UIReturnKeyGo;
    
    _usernameTextField.delegate = self;
    _passwordTextField.delegate = self;
    
    [self checkAuthTokenValidity];
    
}

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

- (void)viewDidAppear:(BOOL)animated
{
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshAuthenticationCredentials:) name:kAuthenticationFromTokenFailed object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tokenValidityPassed:) name:kAuthenticationFromTokenSucceeded object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
}
- (void)viewDidDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kAuthenticationFromTokenFailed object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kAuthenticationFromTokenSucceeded object:nil];
}

- (void)keyboardDidShow:(NSNotification *)notification
{
    [UIView animateKeyframesWithDuration:0.5 delay:0.1 options:UIViewKeyframeAnimationOptionCalculationModeCubic animations:^{
        CGRect frame = self.view.frame;
        frame.origin.y = (frame.origin.y - 60);
        self.view.frame = frame;
    } completion:^(BOOL finished) {
        
    }];
    
}

- (void)keyboardDidHide:(NSNotification *)notification
{
    [UIView animateKeyframesWithDuration:0.5 delay:0.1 options:UIViewKeyframeAnimationOptionCalculationModeCubic animations:^{
        CGRect frame = self.view.frame;
        frame.origin.y = (frame.origin.y + 60);
        self.view.frame = frame;
    } completion:^(BOOL finished) {
        
    }];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == _usernameTextField) {
        [_passwordTextField becomeFirstResponder];
        return NO;
    }
    else {
        [self showWebviewForLogin:nil];
        [_passwordTextField resignFirstResponder];
        return YES;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)showWebviewForLogin:(id)sender {
    username = _usernameTextField.text;
    password = _passwordTextField.text;
    loginAttempts = 0;
    _loginStatusLabel.hidden = YES;
    [self refreshAuthenticationCredentials:nil];
}

- (void)showWebview
{
    [UIView animateWithDuration:0.8
                          delay: 0.0
                        options: UIViewAnimationOptionCurveLinear
                     animations:^{
                         _authWebview.hidden = YES;
                         //_authWebview.alpha = 1.0;
                         
                         
                         NSString *url_path = [NSString stringWithFormat:kOsgiAuthURL, kOAuthClientId, kURLSchemeCallback];
                         NSURL *url = [NSURL URLWithString:url_path];
                         
#if DEBUG
                         [NSURLRequest setAllowsAnyHTTPSCertificate:YES forHost:[url host]];
                         NSLog(@"AUTH PATH: %@", url_path);
#endif
                         
                         [_authWebview loadRequest:[NSURLRequest requestWithURL:url]];
                     }
                     completion:nil];
}

- (void)dismissWebviewForLogin
{
    [UIView animateWithDuration:0.8
                          delay: 0.0
                        options: UIViewAnimationOptionCurveLinear
                     animations:^{
                         _authWebview.alpha = 0.0;
                         _authWebview.hidden = YES;
                         
                         
                     }
                     completion:^(BOOL finished) {
                         //NSNotification *notification = [NSNotification notificationWithName:Nil object:[NSNumber numberWithBool:YES]];
                         [self tokenValidityPassed:nil];
                     }];
}


- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    NSLog(@"Did Failt Load With Error");
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    if (loginAttempts < MAX_LOGIN_ATTEMPTS) {
        [webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.getElementById('username').value = '%@';document.getElementById('password').value = '%@';document.getElementById('go-button').click()", username, password]];
        loginAttempts++;
    }
    else {
        [webView stopLoading];
        _loginStatusLabel.text = NSLocalizedString(@"Invalid username/password", @"Invalid username/password");
        _loginStatusLabel.hidden = NO;
    }
    
}

#pragma mark - UIWebview Delegate

- (BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType {
    //    [indicator startAnimating];
    
#if DEBUG
    NSLog(@"%@", [request description]);
#endif
    
    
    if ([[[request URL] scheme] isEqualToString:@"jiveclient"]) {
        
        // Extract oauth_verifier from URL query
        NSString* verifier = nil;
        NSArray* urlParams = [[[request URL] query] componentsSeparatedByString:@"&"];
        for (NSString* param in urlParams) {
            NSArray* keyValue = [param componentsSeparatedByString:@"="];
            NSString* key = [keyValue objectAtIndex:0];
            if ([key isEqualToString:@"code"]) {
                verifier = [keyValue objectAtIndex:1];
                break;
            }
        }
        
        
        if (verifier)
        {
            NSString *data = [NSString stringWithFormat:@"code=%@&client_id=%@&client_secret=%@&redirect_uri=%@&grant_type=authorization_code", verifier, kOAuthClientId, kOAuthClientSecret, kURLSchemeCallback];
            NSString *url = [NSString stringWithFormat:@"https://auth.jive.com/oauth2/token"];
            NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
            [request setHTTPMethod:@"POST"];
            [request setHTTPBody:[data dataUsingEncoding:NSUTF8StringEncoding]];
            NSString* basicAuth = [@"Basic " stringByAppendingString:[self encodeStringToBase64:[NSString stringWithFormat:@"%@:%@", kOAuthClientId, kOAuthClientSecret]]];
            [request setValue:basicAuth forHTTPHeaderField:@"Authorization"];
            NSURLConnection *theConnection=[[NSURLConnection alloc] initWithRequest:request delegate:self];
            receivedData = [[NSMutableData alloc] init];
            NSLog(@"%@",receivedData);
        }
    }
    
    
    return YES;
}



- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data

{
    [receivedData appendData:data];
    NSLog(@"received Data %@",receivedData);
}
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                    message:[NSString stringWithFormat:@"%@", error]
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSError *error;
    NSDictionary *tokenData = [NSJSONSerialization JSONObjectWithData:receivedData options:kNilOptions error:&error];
    NSLog(@"%@", tokenData);
    if ([tokenData objectForKey:@"access_token"]) {
        NSString* token = [tokenData objectForKey:@"access_token"];
        [[JCAuthenticationManager sharedInstance] didReceiveAuthenticationToken:token];
        //[self tokenValidityPassed:token];
        [self dismissWebviewForLogin];
    }
}

- (void)checkAuthTokenValidity
{
    [[JCAuthenticationManager sharedInstance] checkForTokenValidity];
}

- (void)refreshAuthenticationCredentials:(NSNotification*)notification
{
    AFNetworkReachabilityStatus status = [AFNetworkReachabilityManager sharedManager].networkReachabilityStatus;
    if (status == AFNetworkReachabilityStatusReachableViaWiFi || status == AFNetworkReachabilityStatusReachableViaWWAN) {
        [self showWebview];
    }
    else {
        NSString* token = [[JCAuthenticationManager sharedInstance] getAuthenticationToken];
        if (![self stringIsNilOrEmpty:token]) {
            [self tokenValidityPassed:notification];
        }
        else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Server Unavailable" message:@"We could not connect to the server at this time. Please try again" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
            
            [alert show];
        }
    }
}

-(BOOL)stringIsNilOrEmpty:(NSString*)aString {
    return !(aString && aString.length);
}

- (void)goToApplication
{
    JCAppDelegate *delegate = (JCAppDelegate *)[UIApplication sharedApplication].delegate;
    [delegate changeRootViewController:JCRootTabbarViewController];
}

- (void)tokenValidityPassed:(NSNotification*)notification
{
    [self showHudWithTitle:NSLocalizedString(@"One Moment Please", nil) detail:NSLocalizedString(@"Signing In", nil)];
    [JCVersionTracker start];
    if ([JCVersionTracker isFirstLaunch] || [JCVersionTracker isFirstLaunchSinceUpdate]) {
        [self showHudWithTitle:NSLocalizedString(@"One Moment Please", nil) detail:NSLocalizedString(@"Building Database", nil)];
        [self fetchDataForFirstTime];
    }
    else
    {
        if (!notification) {
            //BOOL fromLogin = (BOOL)notification.object;
            //if (fromLogin) {
            [self showHudWithTitle:NSLocalizedString(@"One Moment Please", nil) detail:NSLocalizedString(@"Building Database", nil)];
            [self fetchDataForFirstTime];
        }
        else {
            NSArray *dataCheck = [ClientEntities MR_findAll];
            
            if (dataCheck.count == 0) {
                [self showHudWithTitle:NSLocalizedString(@"One Moment Please", nil) detail:NSLocalizedString(@"Building Database", nil)];
                [self fetchDataForFirstTime];
            }
            else {
                [self hideHud];
                [self goToApplication];
            }
        }
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"OsgiLoginLogin" object:nil];
}

- (void)fetchDataForFirstTime
{
    [self fetchEntities];
}

- (void)fetchEntities
{
    [[JCOsgiClient sharedClient] RetrieveClientEntitites:^(id JSON) {
        [self fetchPresence];
    } failure:^(NSError *err) {
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
        
        [[JCOmniPresence sharedInstance] me].entityCompany = company;
        
        [localContext MR_saveToPersistentStoreAndWait];
        
        [self hideHud];
        [self goToApplication];
        
    } failure:^(NSError *err) {
        NSLog(@"%@", err);
        [self errorInitializingApp];
    }];

}

- (void)errorInitializingApp
{
    [self hideHud];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Server Unavailable" message:@"We could not connect to the server at this time. Please try again" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
    
    [alert show];
    [[JCAuthenticationManager sharedInstance] logout:self];
}

#pragma mark Base64 Util
- (NSString*)encodeStringToBase64:(NSString*)plainString
{
    NSData *plainData = [plainString dataUsingEncoding:NSUTF8StringEncoding];
    NSString *base64String = [plainData base64EncodedStringWithOptions:0];
    NSLog(@"%@", base64String);
    return base64String;
}

- (NSString*)decodeBase64ToString:(NSString*)base64String
{
    NSData *decodedData = [[NSData alloc] initWithBase64EncodedString:base64String options:0];
    NSString *decodedString = [[NSString alloc] initWithData:decodedData encoding:NSUTF8StringEncoding];
    NSLog(@"%@", decodedString); // foo
    return decodedString;
}


@end
