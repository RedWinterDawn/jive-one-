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
#import "JCVersionTracker.h"
#import <MBProgressHUD/MBProgressHUD.h>

@interface JCStartLoginViewController ()
{
    NSMutableData *receivedData;
    MBProgressHUD *hud;
}

@end

#if DEBUG
@interface NSURLRequest(Private)
+(void)setAllowsAnyHTTPSCertificate:(BOOL)inAllow forHost:(NSString *)inHost;
@end
#endif

@implementation JCStartLoginViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    _authWebview.delegate = self;
    
    
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
    [self checkAuthTokenValidity];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshAuthenticationCredentials:) name:kAuthenticationFromTokenFailed object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tokenValidityPassed:) name:kAuthenticationFromTokenSucceeded object:nil];
}
- (void)viewDidDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)showWebviewForLogin:(id)sender {
    
    
    [UIView animateWithDuration:0.8
                          delay: 0.0
                        options: UIViewAnimationOptionCurveLinear
                     animations:^{
                         _authWebview.hidden = NO;
                         _authWebview.alpha = 1.0;
                         
                         
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
                         [self tokenValidityPassed:nil];
                     }];
}


- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    NSLog(@"Did Failt Load With Error");
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    NSLog(@"Webview Did Finish Load");
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
        [self dismissWebviewForLogin];
    }
}

- (void)checkAuthTokenValidity
{
    [[JCAuthenticationManager sharedInstance] checkForTokenValidity];
}

- (void)refreshAuthenticationCredentials:(NSNotification*)notification
{
    [self showWebviewForLogin:nil];
}

- (void)tokenValidityPassed:(NSNotification*)notification
{
    [JCVersionTracker start];
    if ([JCVersionTracker isFirstLaunch] || [JCVersionTracker isFirstLaunchSinceUpdate]) {
        [self showHudWithTitle:NSLocalizedString(@"One Moment Please", nil) detail:NSLocalizedString(@"Fetching Data For 1st Time", nil)];
        [self fetchDataForFirstTime];
    }
    else
    {
        [self performSegueWithIdentifier:@"ApplicationSegue" sender:nil];
    }
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
        [self hideHud];
    }];
}

- (void)fetchPresence
{
    [[JCOsgiClient sharedClient] RetrieveEntitiesPresence:^(BOOL updated) {
        [self hideHud];
        [self performSegueWithIdentifier:@"ApplicationSegue" sender:nil];
    } failure:^(NSError *err) {
        [self hideHud];
    }];
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
