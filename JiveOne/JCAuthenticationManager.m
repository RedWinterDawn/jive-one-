//
//  JCAuthenticationManager.m
//  JiveAppOne
//
//  Created by Eduardo Gueiros on 2/8/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCAuthenticationManager.h"
#import "JCOsgiClient.h"
#import "JCAppDelegate.h"
#import "JCAccountViewController.h"
#import "JCLoginViewController.h"
#import "Common.h"

#if DEBUG
@interface NSURLRequest(Private)
+(void)setAllowsAnyHTTPSCertificate:(BOOL)inAllow forHost:(NSString *)inHost;
@end
#endif

@interface JCAuthenticationManager ()

#define kUserAuthenticated @"keyuserauthenticated"
#define kUserLoadedMinimumData @"keyuserloadedminimumdata"

@property (nonatomic) NSString *username;
@property (nonatomic) NSString *password;

@end

@implementation JCAuthenticationManager
{
    NSMutableData *receivedData;
    UIWebView *webview;
    int loginAttempts;
    NSTimer *webviewTimer;
}

static int MAX_LOGIN_ATTEMPTS = 2;

+ (JCAuthenticationManager *)sharedInstance
{
    static JCAuthenticationManager* sharedObject = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedObject = [[JCAuthenticationManager alloc] init];
        sharedObject.keychainWrapper = [[KeychainItemWrapper alloc] initWithIdentifier:kJiveAuthStore accessGroup:nil];
    });
    return sharedObject;
}

#pragma mark - Class methods
- (void)loginWithUsername:(NSString *)username password:(NSString*)password
{
    NSString *url_path = [NSString stringWithFormat:kOsgiAuthURL, kOAuthClientId, kURLSchemeCallback];
    NSURL *url = [NSURL URLWithString:url_path];
    
    _username = [username stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];;
    _password = [password stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];;
    
#if DEBUG
    [NSURLRequest setAllowsAnyHTTPSCertificate:YES forHost:[url host]];
    NSLog(@"AUTH PATH: %@", url_path);
#endif
    
    if (!webview) {
        webview = [[UIWebView alloc] init];
    }
    
    // start the timeout timer
    webviewTimer = [NSTimer scheduledTimerWithTimeInterval:60.0 target:self selector:@selector(timerElapsed:) userInfo:nil repeats:NO];
    
    webview.delegate = self;
    [webview loadRequest:[NSURLRequest requestWithURL:url]];
}

- (BOOL)userAuthenticated {
    
    // This variable is only for testing
    // Here you have to implement a mechanism to manipulate this
    BOOL auth = [[NSUserDefaults standardUserDefaults]  boolForKey:kUserAuthenticated];
    if (auth) {
        return YES;
    }
    
    return NO;
}

- (BOOL)userLoadedMininumData
{
    BOOL loaded = [[NSUserDefaults standardUserDefaults]  boolForKey:kUserLoadedMinimumData];
    if (loaded) {
        return YES;
    }
    
    return NO;
}

- (void)setUserLoadedMinimumData:(BOOL)loaded
{
    [[NSUserDefaults standardUserDefaults] setBool:loaded forKey:kUserLoadedMinimumData];
    [[NSUserDefaults standardUserDefaults] synchronize];    
}

- (void)didReceiveAuthenticationToken:(NSDictionary *)token
{
    NSString *access_token = token[@"access_token"];
    NSString *refresh_token = token[@"refresh_token"];
    
    [_keychainWrapper setObject:(__bridge id)kSecAttrAccessibleAlways forKey:(__bridge id)kSecAttrAccount];
    [_keychainWrapper setObject:[NSString stringWithFormat:@"%@", access_token] forKey:(__bridge id)(kSecAttrAccount)];
    
    
    [[NSUserDefaults standardUserDefaults] setObject:access_token forKey:@"authToken"];
    if (refresh_token) {
        [[NSUserDefaults standardUserDefaults] setObject:refresh_token forKey:@"refreshToken"];
    }
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kUserAuthenticated];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString *)getAuthenticationToken
{
    NSString *token = [_keychainWrapper objectForKey:(__bridge id)(kSecAttrAccount)];
    return token;
}

- (void)checkForTokenValidity
{
    [self verifyToken];
}

// IBAction method for logout is in the JCAccountViewController.m
- (void)logout:(UIViewController *)viewController {
    
    [self.keychainWrapper resetKeychainItem];
    
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"authToken"];
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"authToken"];
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"refreshToken"];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kUserAuthenticated];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kUserLoadedMinimumData];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [[JCOsgiClient sharedClient] clearCookies];
    [[JCOmniPresence sharedInstance] truncateAllTablesAtLogout];
    
    JCAppDelegate *delegate = (JCAppDelegate *)[UIApplication sharedApplication].delegate;
    
    [delegate stopSocket];
    
    if(![viewController isKindOfClass:[JCLoginViewController class]]){
        [UIView transitionWithView:delegate.window
                          duration:0.5
                           options:UIViewAnimationOptionTransitionFlipFromLeft
                        animations:^{
                            [delegate changeRootViewController:JCRootLoginViewController];
                        }
                        completion:nil];
    }
}


#pragma mark - UIWebview Delegates
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
            [self requestOauthOperation:data type:0];
        }
    }
    return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    if (loginAttempts < MAX_LOGIN_ATTEMPTS) {
        [webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.getElementById('username').value = '%@';document.getElementById('password').value = '%@';document.getElementById('go-button').click()", _username, _password]];
        loginAttempts++;
    }
    else {
        [webView stopLoading];
        loginAttempts = 0;
        [[NSNotificationCenter defaultCenter] postNotificationName:kAuthenticationFromTokenFailed object:nil];
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    NSLog(@"Did Fail Load With Error");
}

#pragma mark - NSURLConnectionDelegate
- (void)requestOauthOperation:(NSString *)data type:(NSInteger)type
{
    NSString *termination;
    
    if (type == 0) {
        termination = @"token";
    }
    else {
        termination = @"verify";
    }
    
    NSString *url = [NSString stringWithFormat:@"https://auth.jive.com/oauth2/%@", termination];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[data dataUsingEncoding:NSUTF8StringEncoding]];
    NSString* basicAuth = [@"Basic " stringByAppendingString:[Common encodeStringToBase64:[NSString stringWithFormat:@"%@:%@", kOAuthClientId, kOAuthClientSecret]]];
    [request setValue:basicAuth forHTTPHeaderField:@"Authorization"];
    NSURLConnection *theConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    
    if (theConnection) {
        receivedData = [[NSMutableData alloc] init];
        NSLog(@"%@",receivedData);
    }
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
    if ([tokenData objectForKey:@"access_token"]) {
        [self didReceiveAuthenticationToken:tokenData];
        [[NSNotificationCenter defaultCenter] postNotificationName:kAuthenticationFromTokenSucceeded object:nil];
        [webviewTimer invalidate];
        
    }
    else if ([tokenData objectForKey:@"valid"])
    {
        BOOL tokenValid = [tokenData[@"valid"] boolValue];
        if (!tokenValid) {
            if ([self userAuthenticated]) {
                [self refreshToken];
            }
            else
            {
                JCAppDelegate *delegate = [UIApplication sharedApplication].delegate;
                if (![delegate.window.rootViewController isKindOfClass:[JCLoginViewController class]]) {
                    [delegate changeRootViewController:JCRootLoginViewController];
                }
                else {
                    [[NSNotificationCenter defaultCenter] postNotificationName:kAuthenticationFromTokenFailed object:nil];
                }
            }
        }
    }
    else
    {
        [self logout:nil];
    }
}

#pragma mark - OAUTH RefreshToken Implementation
- (void)refreshToken
{
    NSString *refreshToken = [[NSUserDefaults standardUserDefaults] objectForKey:@"refreshToken"];
    if (![Common stringIsNilOrEmpty:refreshToken]) {
        NSString *data = [NSString stringWithFormat:@"refresh_token=%@&client_id=%@&redirect_uri=%@&grant_type=refresh_token", refreshToken, kOAuthClientId, kURLSchemeCallback];
        [self requestOauthOperation:data type:0];
    }
    else {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kUserAuthenticated];
        [self checkForTokenValidity];
    }
}

- (void)verifyToken
{
    NSString *token = [self getAuthenticationToken];
    if (![Common stringIsNilOrEmpty:token]) {
        NSString *data = [NSString stringWithFormat:@"token=%@", token];
        [self requestOauthOperation:data type:1];
    }
}


#pragma mark - Timer expired
- (void)timerElapsed:(NSNotification *)notification
{
    [webview stopLoading];
    [[NSNotificationCenter defaultCenter] postNotificationName:kAuthenticationFromTokenFailedWithTimeout object:kAuthenticationFromTokenFailedWithTimeout];
}
@end
