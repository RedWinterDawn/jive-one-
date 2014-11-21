//
//  JCAuthenticationManager.m
//  JiveAppOne
//
//  Created by Eduardo Gueiros on 2/8/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCAuthenticationManager.h"
#import "Common.h"

#import "JCV5ApiClient.h"
#import "KeychainItemWrapper.h"

#define kUserAuthenticated @"keyuserauthenticated"
#define kUserLoadedMinimumData @"keyuserloadedminimumdata"

// Keychain
NSString *const kJCAuthenticationManagerKeychainStoreIdentifier = @"keyjiveauthstore";

// KVO Keys
NSString *const kJCAuthenticationManagerUserAutheticatedAttributeKey = @"userAuthenticated";
NSString *const kJCAuthenticationManagerUserLoadedMinimumDataAttributeKey = @"userLoadedMinimumData";
NSString *const kJCAuthenticationManagerRememberMeAttributeKey = @"userLoadedMinimumData";

// Notifications
NSString *const kJCAuthenticationManagerUserLoggedOutNotification = @"userLoggedOut";
NSString *const kJCAuthenticationManagerUserAuthenticatedNotification = @"userAuthenticated";
NSString *const kJCAuthenticationManagerUserLoadedMinimumDataNotification = @"userLoadedMinimumData";

static int MAX_LOGIN_ATTEMPTS = 2;

#if DEBUG
@interface NSURLRequest(Private)
+(void)setAllowsAnyHTTPSCertificate:(BOOL)inAllow forHost:(NSString *)inHost;
@end
#endif

@interface JCAuthenticationManager () <UIWebViewDelegate>
{
    NSMutableData *receivedData;
    
    int loginAttempts;
    
    KeychainItemWrapper *_keychainWrapper;
    CompletionBlock _completionBlock;
    
    NSString *_username;
    NSString *_password;
    UIWebView *_webview;
    
    BOOL _useWebView;
}

@property (nonatomic, readwrite) NSString *userName;
@property (nonatomic, readwrite) NSString *authToken;
@property (nonatomic, readwrite) NSString *refreshToken;
@property (nonatomic, readwrite) BOOL userAuthenticated;

@end

@implementation JCAuthenticationManager

-(instancetype)init
{
    self = [super init];
    if (self) {
        _keychainWrapper = [[KeychainItemWrapper alloc] initWithIdentifier:kJCAuthenticationManagerKeychainStoreIdentifier accessGroup:nil];
        _useWebView = TRUE;
    }
    return self;
}

#pragma mark - Class methods

- (void)loginWithUsername:(NSString *)username password:(NSString *)password completed:(CompletionBlock)completed
{
    _completionBlock = completed;
    _username = [username stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    _password = [password stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    NSString *url_path = [NSString stringWithFormat:kOsgiAuthURL, kOAuthClientId, kScopeProfile, kURLSchemeCallback];
    NSURL *url = [NSURL URLWithString:url_path];
    
#if DEBUG
    [NSURLRequest setAllowsAnyHTTPSCertificate:YES forHost:[url host]];
    NSLog(@"AUTH PATH: %@", url_path);
#endif
    
    [self requestAuthenticationUsingWebview:url];
}

- (void)logout
{
    [_keychainWrapper resetKeychainItem];
    
    // Clear out all the saved data.
    self.authToken = nil;
    self.refreshToken = nil;
    self.userLoadedMininumData = false;
    self.userAuthenticated = false;
    
    if (!self.rememberMe) {
        self.userName = false;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kJCAuthenticationManagerUserLoggedOutNotification object:self userInfo:nil];
}

#pragma mark - Setters -

-(void)setUserAuthenticated:(BOOL)userAuthenticated
{
    [self willChangeValueForKey:kJCAuthenticationManagerUserAutheticatedAttributeKey];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:YES forKey:kUserAuthenticated];
    [defaults synchronize];
    [self didChangeValueForKey:kJCAuthenticationManagerUserAutheticatedAttributeKey];
    
    if (userAuthenticated)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:kJCAuthenticationManagerUserAuthenticatedNotification object:self userInfo:nil];
    }
}

-(void)setUserLoadedMininumData:(BOOL)userLoadedMininumData
{
    [self willChangeValueForKey:kJCAuthenticationManagerUserLoadedMinimumDataAttributeKey];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:userLoadedMininumData forKey:kUserLoadedMinimumData];
    [defaults synchronize];
    [self didChangeValueForKey:kJCAuthenticationManagerUserLoadedMinimumDataAttributeKey];
    
    if (userLoadedMininumData) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kJCAuthenticationManagerUserLoadedMinimumDataNotification object:self userInfo:nil];
    }
}

-(void)setRememberMe:(BOOL)remember
{
    [self willChangeValueForKey:kJCAuthenticationManagerRememberMeAttributeKey];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:remember forKey:kRememberMe];
    [defaults synchronize];
    [self didChangeValueForKey:kJCAuthenticationManagerRememberMeAttributeKey];
}

-(void)setAuthToken:(NSString *)authToken
{
    [_keychainWrapper setObject:(__bridge id)kSecAttrAccessibleAlways forKey:(__bridge id)kSecAttrAccount];
    [_keychainWrapper setObject:(__bridge id)kSecAttrAccessibleAlways forKey:(__bridge id)kSecValueData];
    [_keychainWrapper setObject:[NSString stringWithFormat:@"%@", authToken] forKey:(__bridge id)(kSecAttrAccount)];
    [_keychainWrapper setObject:[NSString stringWithFormat:@"%@", authToken] forKey:(__bridge id)(kSecValueData)];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:authToken forKey:@"authToken"];
    [defaults synchronize];
}

-(void)setRefreshToken:(NSString *)refreshToken
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:refreshToken forKey:@"refreshToken"];
    [defaults synchronize];
}

-(void)setUserName:(NSString *)userName
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:userName forKey:kUserName];
    [defaults synchronize];
}

#pragma mark - Getters -

- (BOOL)userAuthenticated
{
    return [[NSUserDefaults standardUserDefaults]  boolForKey:kUserAuthenticated];
}

- (BOOL)userLoadedMininumData
{
    return [[NSUserDefaults standardUserDefaults]  boolForKey:kUserLoadedMinimumData];
}

- (BOOL)rememberMe
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:kRememberMe];
}

-(NSString *)authToken
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
    
    if ([Common stringIsNilOrEmpty:token]){
        token = [[NSUserDefaults standardUserDefaults] objectForKey:@"authToken"];
    }
    
    return token;
}

-(NSString *)refreshToken
{
    return [[NSUserDefaults standardUserDefaults] valueForKey:@"refreshToken"];
}

-(NSString *)userName
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:kUserName];
}

-(PBX *)pbx
{
    // TODO: When we are able to handle multiple PBX's return selected PBX, until then, returh the first.
    
    return [PBX MR_findFirst];
}

-(Lines *)line
{
    // TODO: When we are able to handle multiple Lines return selected Line, until then, returh the first.
    
    return [Lines MR_findFirst];
}

-(LineConfiguration *)lineConfiguration
{
    // TODO: When we are able to handle multiple Line configurations return selected Line configuration, until then, returh the first.
    
    return [LineConfiguration MR_findFirst];
}

-(NSString *)lineDisplayName
{
    return self.line.displayName;
}

-(NSString *)lineExtension
{
    return self.line.externsionNumber;
}

-(NSString *)pbxName
{
    PBX *pbx = self.pbx;
    if (pbx)
        return [NSString stringWithFormat:@"%@ PBX on %@", pbx.name, [pbx.v5 boolValue] ? @"V5" : @"V4"];
    return nil;
}

#pragma mark - Private -

-(void)requestAuthenticationUsingWebview:(NSURL *)url
{
    if (!_webview) {
        _webview = [[UIWebView alloc] init];
    }
    _webview.delegate = self;
    [_webview loadRequest:[NSURLRequest requestWithURL:url]];
}

/**
 * IF WE CAN EVER HIT AN API AGAIN, THIS IS WHAT WE WOULD USE
 */
-(void)requestAuthenticationUsingWebservice:(NSURL *)url
{
    //[self.client OAuthLoginWithUsername:username password:password success:^(AFHTTPRequestOperation *operation, id JSON) {
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
    //}];
}

- (void)didReceiveAuthenticationToken:(NSDictionary *)token
{
    self.authToken      = token[@"access_token"];
    self.refreshToken   = token[@"refresh_token"];
    self.userName       = token[@"username"];
    self.userAuthenticated = TRUE;
    
    //[(JCAppDelegate *)[UIApplication sharedApplication].delegate didLogInSoCanRegisterForPushNotifications];
}

- (void)checkForTokenValidity
{
    //Rolling back to hack
    //[self verifyToken];
    NSString *username = self.userName;
    [[JCV5ApiClient sharedClient] getMailboxReferencesForUser:username completed:^(BOOL suceeded, id responseObject, AFHTTPRequestOperation *operation, NSError *error) {
        if (suceeded) {
            //JCAppDelegate *delegate = (JCAppDelegate *)[UIApplication sharedApplication].delegate;
            //if (![delegate.window.rootViewController isKindOfClass:[JCLoginViewController class]]) {
                [[NSNotificationCenter defaultCenter] postNotificationName:kAuthenticationFromTokenSucceeded object:responseObject];
            //}
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
                [[NSNotificationCenter defaultCenter] postNotificationName:kAuthenticationFromTokenFailed object:nil];
                //                }
            }
            else {
                NSLog(@"%@", operation.response);
            }
        }

    }];
    


}

-(void)sendCompletionBlock:(BOOL)success errorMessage:(NSString *)errorMessage {
    
    NSError *error = nil;
    if (!success) {
        NSMutableDictionary *detail = [NSMutableDictionary dictionary];
        [detail setValue:errorMessage forKey:NSLocalizedDescriptionKey];
        error = [[NSError alloc] initWithDomain:@"auth" code:500 userInfo:detail];
    }
    
    if (_completionBlock) {
        _completionBlock(success, error);
    }
    
    // done with block
    _completionBlock = nil;
    
}

#pragma mark - Delegate Handlers -

#pragma mark UIWebviewDelegate

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

- (BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType {
    
#if DEBUG
    NSLog(@"%@", [request description]);
#endif
    
    if ([[[request URL] scheme] isEqualToString:@"jiveclient"])
    {
        
        NSString *stringURL = [[request URL] description];
        NSArray *topLevel =  [stringURL componentsSeparatedByString:@"#"];
        NSArray *urlParams = [topLevel[1] componentsSeparatedByString:@"&"];
        
        NSMutableDictionary *tokenData = nil;
        
        for (NSString *param in urlParams) {
            
            if (!tokenData) {
                tokenData = [[NSMutableDictionary alloc] init];
            }
            
            NSArray* keyValue = [param componentsSeparatedByString:@"="];
            NSString* key = [keyValue objectAtIndex:0];
            NSString* value = [keyValue objectAtIndex:1];
            
            [tokenData setObject:value forKey:key];
        }
        
        if (tokenData && tokenData.count > 0)
        {
            if ([tokenData objectForKey:@"access_token"]) {
                [self didReceiveAuthenticationToken:tokenData];
                [self sendCompletionBlock:YES errorMessage:nil];
            }
            else {
                if (tokenData[@"error"]) {
                    [self sendCompletionBlock:NO errorMessage:tokenData[@"error"]];
                }
                else {
                    [self sendCompletionBlock:NO errorMessage:NSLocalizedString(@"An Error Has Occurred, Please Try Again",  nil)];
                }
            }
        }
    }
    return YES;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    NSLog(@"Did Fail Load With Error");
    [self sendCompletionBlock:NO errorMessage:NSLocalizedString(@"An Error Has Occurred, Please Try Again",  nil)];
}

/*
//#pragma mark - NSURLConnectionDelegate
//- (void)requestAccessToken:(NSString *)data
//{
//    NSString *url = [NSString stringWithFormat:@"https://auth.jive.com/oauth2/v2/token"];
//    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
//    [request setHTTPMethod:@"POST"];
//    [request setHTTPBody:[data dataUsingEncoding:NSUTF8StringEncoding]];
//    NSString* basicAuth = [@"Basic " stringByAppendingString:[Common encodeStringToBase64:[NSString stringWithFormat:@"%@:%@", kOAuthClientId, kOAuthClientSecret]]];
//    [request setValue:basicAuth forHTTPHeaderField:@"Authorization"];
//    NSURLConnection *theConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
//    
//    if (theConnection) {
//        receivedData = [[NSMutableData alloc] init];
//        //NSLog(@"%@",receivedData);
//    }
//}
//
//- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
//
//{
//    [receivedData appendData:data];
//    //NSLog(@"received Data %@",receivedData);
//}
//- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
//    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
//                                                    message:[NSString stringWithFormat:@"%@", error]
//                                                   delegate:nil
//                                          cancelButtonTitle:@"OK"
//                                          otherButtonTitles:nil];
//    [alert show];
//}
//
//- (void)connectionDidFinishLoading:(NSURLConnection *)connection
//{
//    NSError *error;
//    NSDictionary *tokenData = [NSJSONSerialization JSONObjectWithData:receivedData options:kNilOptions error:&error];
//    if ([tokenData objectForKey:@"access_token"]) {
//        [self didReceiveAuthenticationToken:tokenData];
//        //[[NSNotificationCenter defaultCenter] postNotificationName:kAuthenticationFromTokenSucceeded object:nil];
//        
//    }
//    else {
//        if (tokenData[@"error"]) {
//            NSLog(@"%@", tokenData);
//        }
//    }
//}
//
//#pragma mark - OAUTH RefreshToken Implementation
//
//- (void)refreshToken
//{
//    NSString *refreshToken = self.refreshToken;
//    if (![Common stringIsNilOrEmpty:refreshToken]) {
//        NSString *data = [NSString stringWithFormat:@"refresh_token=%@&client_id=%@&redirect_uri=%@&grant_type=refresh_token", refreshToken, kOAuthClientId, kURLSchemeCallback];
//        [self requestAccessToken:data];
//    }
//}
//
//#pragma mark - Timer expired
//- (void)timerElapsed:(NSNotification *)notification
//{
//    [_webview stopLoading];
//    //[[NSNotificationCenter defaultCenter] postNotificationName:kAuthenticationFromTokenFailed object:nil];
//    [self sendCompletionBlock:NO errorMessage:NSLocalizedString(@"An Error Has Occured, Please Try Again",  nil)];
//}
//
//
//
//

//#pragma makr - Depracated for Oauth v1.
//#pragma mark - NSURLConnectionDelegate
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
 */
@end


@implementation JCAuthenticationManager (Singleton)

+ (instancetype)sharedInstance
{
    static JCAuthenticationManager* autheticationManager = nil;
    static dispatch_once_t autheticationManagerOnceToken;
    dispatch_once(&autheticationManagerOnceToken, ^{
        autheticationManager = [[JCAuthenticationManager alloc] init];
    });
    return autheticationManager;
}

@end
