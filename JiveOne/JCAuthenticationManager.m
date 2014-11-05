//
//  JCAuthenticationManager.m
//  JiveAppOne
//
//  Created by Eduardo Gueiros on 2/8/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCAuthenticationManager.h"
#import "JCAppDelegate.h"
#import "JCAccountViewController.h"
#import "JCLoginViewController.h"
#import "Common.h"
#import "JCSocketDispatch.h"
#import "SipHandler.h"
#import "JCApplicationSwitcherDelegate.h"
#import "JCV5ApiClient.h"
#import "JCBadgeManager.h"

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
//@property (nonatomic, strong) JCRESTClient *client;

@end

@implementation JCAuthenticationManager
{
    NSMutableData *receivedData;
    UIWebView *webview;
    int loginAttempts;
    NSTimer *webviewTimer;
}

//- (void) setClient:(JCRESTClient *)client
//{
//    _client = client;
//}

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
- (void)loginWithUsername:(NSString *)username password:(NSString*)password completed:(CompletionBlock)completed
{
    _completionBlock = completed;
    NSString *url_path = [NSString stringWithFormat:kOsgiAuthURL, kOAuthClientId, kScopeProfile, kURLSchemeCallback];
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
//    webviewTimer = [NSTimer scheduledTimerWithTimeInterval:20.0 target:self selector:@selector(timerElapsed:) userInfo:nil repeats:NO];
    
    webview.delegate = self;
    [webview loadRequest:[NSURLRequest requestWithURL:url]];

/* IF WE CAN EVER HIT AN API AGAIN, THIS IS WHAT WE WOULD USE
//    [self.client OAuthLoginWithUsername:username password:password success:^(AFHTTPRequestOperation *operation, id JSON) {
//        
//        if (JSON[@"access_token"]) {
//            
//            [self didReceiveAuthenticationToken:JSON];
//            completed(YES, nil);
//            
//        }
//        else {
//            
//            NSInteger statusCode = 0;
//            if (operation.response) {
//                statusCode = operation.response.statusCode;
//            }
//            
//            NSError *error;
//            if (JSON[@"error"]) {
//                error = [NSError errorWithDomain:@"com.jive.JiveOne" code:statusCode userInfo:JSON];
//            }
//            else {
//                NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"An Unknown Error has occurred. Please try again. If the problem persists contact support", nil), @"error", nil];
//                error = [NSError errorWithDomain:@"com.jive.JiveOne" code:statusCode userInfo:dictionary];
//            }
//            
//            completed(NO, error);
//        }
//        
//    } failure:^(AFHTTPRequestOperation *operation, NSError *err) {
//        
//        NSInteger statusCode = 0;
//        if (operation.response) {
//            statusCode = operation.response.statusCode;
//        }
//        
//        NSError *error;
//        if (operation.responseObject[@"error"]) {
//            error = [NSError errorWithDomain:@"com.jive.JiveOne" code:statusCode userInfo:operation.responseObject];
//        }
//        else {
//            NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"An Unknown Error has occurred. Please try again. If the problem persists contact support", nil), @"error", nil];
//            error = [NSError errorWithDomain:@"com.jive.JiveOne" code:statusCode userInfo:dictionary];
//        }
//        
//        completed(NO, error);
    }];
 */
 
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
    NSString *username = token[@"username"];
    
    [_keychainWrapper setObject:(__bridge id)kSecAttrAccessibleAlways forKey:(__bridge id)kSecAttrAccount];
    [_keychainWrapper setObject:(__bridge id)kSecAttrAccessibleAlways forKey:(__bridge id)kSecValueData];
    [_keychainWrapper setObject:[NSString stringWithFormat:@"%@", access_token] forKey:(__bridge id)(kSecAttrAccount)];
    [_keychainWrapper setObject:[NSString stringWithFormat:@"%@", access_token] forKey:(__bridge id)(kSecValueData)];
    
    
    [[NSUserDefaults standardUserDefaults] setObject:access_token forKey:@"authToken"];
    if (refresh_token) {
        [[NSUserDefaults standardUserDefaults] setObject:refresh_token forKey:@"refreshToken"];
    }
    if (username) {
//        username = [username stringByReplacingOccurrencesOfString:@"." withString:@"_"];
        [[NSUserDefaults standardUserDefaults] setObject:username forKey:kUserName];
    }
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kUserAuthenticated];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [(JCAppDelegate *)[UIApplication sharedApplication].delegate didLogInSoCanRegisterForPushNotifications];
}

- (void)setRememberMe:(BOOL)remember
{
    if (remember) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kRememberMe];
    }
    else {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kRememberMe];
    }
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)getRememberMe {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kRememberMe];
}

- (NSString *)getAuthenticationToken
{
    NSString *token = [_keychainWrapper objectForKey:(__bridge id)(kSecAttrAccount)];
    NSString *bgToken = [_keychainWrapper objectForKey:(__bridge id)(kSecValueData)];
    
    if (![bgToken isEqualToString:token] && ![Common stringIsNilOrEmpty:token]) {
        [_keychainWrapper setObject:[NSString stringWithFormat:@"%@", token] forKey:(__bridge id)(kSecValueData)];
        return token;
    }
    
    if ([Common stringIsNilOrEmpty:token]) {
        token = [_keychainWrapper objectForKey:(__bridge id)(kSecValueData)];
    }
    
    if ([Common stringIsNilOrEmpty:token]) {
        token = [[NSUserDefaults standardUserDefaults] objectForKey:@"authToken"];
    }
    
    return token;
}

- (void)checkForTokenValidity
{
    //Rolling back to hack
    //[self verifyToken];
    NSString *username = [[NSUserDefaults standardUserDefaults] objectForKey:@"username"];
    [[JCV5ApiClient sharedClient] getMailboxReferencesForUser:username completed:^(BOOL suceeded, id responseObject, AFHTTPRequestOperation *operation, NSError *error) {
        if (suceeded) {
            JCAppDelegate *delegate = (JCAppDelegate *)[UIApplication sharedApplication].delegate;
            if (![delegate.window.rootViewController isKindOfClass:[JCLoginViewController class]]) {
                [[NSNotificationCenter defaultCenter] postNotificationName:kAuthenticationFromTokenSucceeded object:responseObject];
            }
        }
        else {
            NSLog(@"%@", error);
            
            NSInteger status = operation.response.statusCode;
            
            if ((status >= 400 && status <= 417) || status == 200) {
                // Since we're not keeping the user logged in with a verifyToken,
                // this code has been commentend. This will change, however, so leave it here.
                //                if ([self userAuthenticated]) {
                //                    [self refreshToken];
                //                }
                //                else
                //                {
                JCAppDelegate *delegate = (JCAppDelegate *)[UIApplication sharedApplication].delegate;
                if (![delegate.window.rootViewController isKindOfClass:[JCLoginViewController class]]) {
                    //[delegate changeRootViewController:JCRootLoginViewController];
                }
                else {
                    [[NSNotificationCenter defaultCenter] postNotificationName:kAuthenticationFromTokenFailed object:nil];
                }
                //                }
            }
            else {
                NSLog(@"%@", operation.response);
            }
        }

    }];
    


}

// IBAction method for logout is in the JCAccountViewController.m
- (void)logout:(UIViewController *)viewController {
    
    [self.keychainWrapper resetKeychainItem];
    
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"authToken"];
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"refreshToken"];
    
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kUserAuthenticated];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kUserLoadedMinimumData];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    if (![self getRememberMe]) {
        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:kUserName];
    }
	
	[[JCV5ApiClient sharedClient] stopAllOperations];
    [[JCOmniPresence sharedInstance] truncateAllTablesAtLogout];
	[[SipHandler sharedHandler] disconnect];

    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
	[JCApplicationSwitcherDelegate reset];
    [[JCBadgeManager sharedManager] reset];
	
    JCAppDelegate *delegate = (JCAppDelegate *)[UIApplication sharedApplication].delegate;
    [delegate didLogOutSoUnRegisterForPushNotifications];
    [delegate stopSocket];
	[delegate changeRootViewController:JCRootLoginViewController];
    
	
}

#pragma mark - UIWebview Delegates
- (BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType {
    //    [indicator startAnimating];
    
#if DEBUG
    NSLog(@"%@", [request description]);
#endif
    
    if ([[[request URL] scheme] isEqualToString:@"jiveclient"]) {
        
        // Extract oauth_verifier from URL query
//        NSString* verifier = nil;
        NSString *stringURL = [[request URL] description];
        NSArray *topLevel =  [stringURL componentsSeparatedByString:@"#"];
        NSArray* urlParams = [topLevel[1] componentsSeparatedByString:@"&"];
        
        NSMutableDictionary *tokenData = nil;
        
        for (NSString* param in urlParams) {
            
            if (!tokenData) {
                tokenData = [[NSMutableDictionary alloc] init];
            }
            
            NSArray* keyValue = [param componentsSeparatedByString:@"="];
            NSString* key = [keyValue objectAtIndex:0];
            NSString* value = [keyValue objectAtIndex:1];
            
            [tokenData setObject:value forKey:key];
            
//            if ([key isEqualToString:@"code"]) {
//                verifier = [keyValue objectAtIndex:1];
//                break;
//            }
        }
        
        
        
        
        if (tokenData && tokenData.count > 0)
        {
            if ([tokenData objectForKey:@"access_token"]) {
                [self didReceiveAuthenticationToken:tokenData];
                //[[NSNotificationCenter defaultCenter] postNotificationName:kAuthenticationFromTokenSucceeded object:nil];
                [webviewTimer invalidate];
                [self sendCompletionBlock:YES errorMessage:nil];
                
            }
            else {
                if (tokenData[@"error"]) {
                    NSLog(@"%@", tokenData);
                    [self sendCompletionBlock:NO errorMessage:tokenData[@"error"]];
                }
                else {
                    [self sendCompletionBlock:NO errorMessage:NSLocalizedString(@"An Error Has Occured, Please Try Again",  nil)];
                }
            }
//            NSString *data = [NSString stringWithFormat:@"code=%@&client_id=%@&client_secret=%@&redirect_uri=%@&grant_type=authorization_code", verifier, kOAuthClientId, kOAuthClientSecret, kURLSchemeCallback];
//            [self requestAccessToken:data];
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
        [self sendCompletionBlock:NO errorMessage:NSLocalizedString(@"Invalid Username/Password. Please try again.",  nil)];
        //[[NSNotificationCenter defaultCenter] postNotificationName:kAuthenticationFromTokenFailed object:nil];
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    NSLog(@"Did Fail Load With Error");
    [self sendCompletionBlock:NO errorMessage:NSLocalizedString(@"An Error Has Occured, Please Try Again",  nil)];
}

#pragma mark - Set CompletionBlock
-(void)sendCompletionBlock:(BOOL)success errorMessage:(NSString *)errorMessage {
    
    NSError *error = nil;
    if (!success) {
        NSMutableDictionary *detail = [NSMutableDictionary dictionary];
        [detail setValue:errorMessage forKey:NSLocalizedDescriptionKey];
        error = [[NSError alloc] initWithDomain:@"auth" code:500 userInfo:detail];
    }
    
    if (self.completionBlock) {
        self.completionBlock(success, error);
    }
    
    // done with block
    _completionBlock = nil;
    
}

#pragma mark - NSURLConnectionDelegate
- (void)requestAccessToken:(NSString *)data
{
    NSString *url = [NSString stringWithFormat:@"https://auth.jive.com/oauth2/v2/token"];
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
    //NSLog(@"received Data %@",receivedData);
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
        //[[NSNotificationCenter defaultCenter] postNotificationName:kAuthenticationFromTokenSucceeded object:nil];
        [webviewTimer invalidate];
        
    }
    else {
        if (tokenData[@"error"]) {
            NSLog(@"%@", tokenData);
        }
    }
}

#pragma mark - OAUTH RefreshToken Implementation
- (void)refreshToken
{
    NSString *refreshToken = [[NSUserDefaults standardUserDefaults] objectForKey:@"refreshToken"];
    if (![Common stringIsNilOrEmpty:refreshToken]) {
        NSString *data = [NSString stringWithFormat:@"refresh_token=%@&client_id=%@&redirect_uri=%@&grant_type=refresh_token", refreshToken, kOAuthClientId, kURLSchemeCallback];
        [self requestAccessToken:data];
    }
}

#pragma mark - Timer expired
- (void)timerElapsed:(NSNotification *)notification
{
    [webview stopLoading];
    //[[NSNotificationCenter defaultCenter] postNotificationName:kAuthenticationFromTokenFailed object:nil];
    [self sendCompletionBlock:NO errorMessage:NSLocalizedString(@"An Error Has Occured, Please Try Again",  nil)];
}




#pragma makr - Depracated for Oauth v1.
#pragma mark - NSURLConnectionDelegate
//- (void)requestOauthOperation:(NSString *)data type:(NSInteger)type
//{
//    NSString *termination;
//    
//    if (type == 0) {
//        termination = @"token";
//    }
//    else {
//        termination = @"verify";
//    }
//    
//    NSString *url = [NSString stringWithFormat:@"https://auth.jive.com/oauth2/%@", termination];
//    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
//    [request setHTTPMethod:@"POST"];
//    [request setHTTPBody:[data dataUsingEncoding:NSUTF8StringEncoding]];
//    NSString* basicAuth = [@"Basic " stringByAppendingString:[Common encodeStringToBase64:[NSString stringWithFormat:@"%@:%@", kOAuthClientId, kOAuthClientSecret]]];
//    [request setValue:basicAuth forHTTPHeaderField:@"Authorization"];
//    NSURLConnection *theConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
//    
//    if (theConnection) {
//        receivedData = [[NSMutableData alloc] init];
//        NSLog(@"%@",receivedData);
//    }
//}
//
//- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
//
//{
//    [receivedData appendData:data];
//    NSLog(@"received Data %@",receivedData);
//}
//- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
//    NSLog(@"Error did occurr %@", error);
//    NSLog(@"URL: %@", connection.currentRequest.URL);
//    NSLog(@"BaseURL: %@", connection.currentRequest.URL.baseURL);
//    if ([[connection.currentRequest.URL description] isEqualToString:@"https://auth.jive.com/oauth2/verify"]) {
//        [self verifyToken];
//    }
//}
//
//- (void)connectionDidFinishLoading:(NSURLConnection *)connection
//{
//    NSError *error;
//    NSDictionary *tokenData = [NSJSONSerialization JSONObjectWithData:receivedData options:kNilOptions error:&error];
//    if ([tokenData objectForKey:@"access_token"]) {
//        [self didReceiveAuthenticationToken:tokenData];
//        [[NSNotificationCenter defaultCenter] postNotificationName:kAuthenticationFromTokenSucceeded object:nil];
//        [webviewTimer invalidate];
//        // if we received a new token, then close socket and restart
//        //[[JCSocketDispatch sharedInstance] closeSocket];
//        //[[JCSocketDispatch sharedInstance] requestSession];
//    }
//    else if ([tokenData objectForKey:@"valid"])
//    {
//        BOOL tokenValid = [tokenData[@"valid"] boolValue];
//        if (!tokenValid) {
//            if ([self userAuthenticated]) {
//                [self refreshToken];
//            }
//            else
//            {
//                JCAppDelegate *delegate = (JCAppDelegate *)[UIApplication sharedApplication].delegate;
//                if (![delegate.window.rootViewController isKindOfClass:[JCLoginViewController class]]) {
//                    [delegate changeRootViewController:JCRootLoginViewController];
//                }
//                else {
//                    [[NSNotificationCenter defaultCenter] postNotificationName:kAuthenticationFromTokenFailed object:nil];
//                }
//            }
//        }
//    }
//}

//#pragma mark - OAUTH RefreshToken Implementation
//- (void)refreshToken
//{
//    NSString *refreshToken = [[NSUserDefaults standardUserDefaults] objectForKey:@"refreshToken"];
//    if (![Common stringIsNilOrEmpty:refreshToken]) {
//        NSString *data = [NSString stringWithFormat:@"refresh_token=%@&client_id=%@&redirect_uri=%@&grant_type=refresh_token", refreshToken, kOAuthClientId, kURLSchemeCallback];
//        [self requestOauthOperation:data type:0];
//    }
//    else {
//        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kUserAuthenticated];
//        [self checkForTokenValidity];
//    }
//}
//
//- (void)verifyToken
//{
//    NSString *token = [self getAuthenticationToken];
//    if (![Common stringIsNilOrEmpty:token]) {
//        NSString *data = [NSString stringWithFormat:@"token=%@", token];
//        [self requestOauthOperation:data type:1];
//    }
//}

//
//#pragma mark - Timer expired
//- (void)timerElapsed:(NSNotification *)notification
//{
//    //[webview stopLoading];
//    [[NSNotificationCenter defaultCenter] postNotificationName:kAuthenticationFromTokenFailedWithTimeout object:kAuthenticationFromTokenFailedWithTimeout];
//}
@end
