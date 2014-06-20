//
//  JCAuthenticationManager.m
//  JiveAppOne
//
//  Created by Eduardo Gueiros on 2/8/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCAuthenticationManager.h"
#import "JCRESTClient.h"
#import "JCAppDelegate.h"
#import "JCAccountViewController.h"
#import "JCLoginViewController.h"
#import "Common.h"
#import "JCSocketDispatch.h"

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
@property (nonatomic, strong) JCRESTClient *client;

@end

@implementation JCAuthenticationManager
{
    NSMutableData *receivedData;
    //UIWebView *webview;
    int loginAttempts;
    NSTimer *webviewTimer;
}

- (void) setClient:(JCRESTClient *)client
{
    _client = client;
}

//static int MAX_LOGIN_ATTEMPTS = 2;

+ (JCAuthenticationManager *)sharedInstance
{
    static JCAuthenticationManager* sharedObject = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedObject = [[JCAuthenticationManager alloc] init];
        sharedObject.keychainWrapper = [[KeychainItemWrapper alloc] initWithIdentifier:kJiveAuthStore accessGroup:nil];
        [sharedObject setClient:[JCRESTClient sharedClient]];
    });
    return sharedObject;
}

#pragma mark - Class methods
- (void)loginWithUsername:(NSString *)username password:(NSString*)password completed:(void (^)(BOOL success, NSError *error)) completed;
{
    NSString *url_path = [NSString stringWithFormat:kOsgiAuthURL, kOAuthClientId, kURLSchemeCallback];
    NSURL *url = [NSURL URLWithString:url_path];
    
    _username = [username stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];;
    _password = [password stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];;
    
#if DEBUG
    [NSURLRequest setAllowsAnyHTTPSCertificate:YES forHost:[url host]];
    NSLog(@"AUTH PATH: %@", url_path);
#endif
    
    [self.client OAuthLoginWithUsername:username password:password success:^(AFHTTPRequestOperation *operation, id JSON) {
        
        if (JSON[@"access_token"]) {
            
            [self didReceiveAuthenticationToken:JSON];
            completed(YES, nil);
            
        }
        else {
            
            NSInteger statusCode = 0;
            if (operation.response) {
                statusCode = operation.response.statusCode;
            }
            
            NSError *error;
            if (JSON[@"error"]) {
                error = [NSError errorWithDomain:@"com.jive.JiveOne" code:statusCode userInfo:JSON];
            }
            else {
                NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"An Unknown Error has occurred. Please try again. If the problem persists contact support", nil), @"error", nil];
                error = [NSError errorWithDomain:@"com.jive.JiveOne" code:statusCode userInfo:dictionary];
            }
            
            completed(NO, error);
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *err) {
        
        NSInteger statusCode = 0;
        if (operation.response) {
            statusCode = operation.response.statusCode;
        }
        
        NSError *error;
        if (operation.responseObject[@"error"]) {
            error = [NSError errorWithDomain:@"com.jive.JiveOne" code:statusCode userInfo:operation.responseObject];
        }
        else {
            NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"An Unknown Error has occurred. Please try again. If the problem persists contact support", nil), @"error", nil];
            error = [NSError errorWithDomain:@"com.jive.JiveOne" code:statusCode userInfo:dictionary];
        }
        
        completed(NO, error);
    }];
    
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
        username = [username stringByReplacingOccurrencesOfString:@"." withString:@"_"];
        [[NSUserDefaults standardUserDefaults] setObject:username forKey:@"username"];
    }
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kUserAuthenticated];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [(JCAppDelegate *)[UIApplication sharedApplication].delegate didLogInSoCanRegisterForPushNotifications];
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
    [self verifyToken];
}

// IBAction method for logout is in the JCAccountViewController.m
- (void)logout:(UIViewController *)viewController {
    
    [self.keychainWrapper resetKeychainItem];
    
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"authToken"];
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"refreshToken"];
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"username"];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kUserAuthenticated];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kUserLoadedMinimumData];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [[JCRESTClient sharedClient] clearCookies];
    [[JCOmniPresence sharedInstance] truncateAllTablesAtLogout];
    
    
    JCAppDelegate *delegate = (JCAppDelegate *)[UIApplication sharedApplication].delegate;
    [delegate didLogOutSoUnRegisterForPushNotifications];
    [delegate stopSocket];
    
    if(![viewController isKindOfClass:[JCLoginViewController class]]){
        [delegate changeRootViewController:JCRootLoginViewController];
    }
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
    NSLog(@"Error did occurr %@", error);
    NSLog(@"URL: %@", connection.currentRequest.URL);
    NSLog(@"BaseURL: %@", connection.currentRequest.URL.baseURL);
    if ([[connection.currentRequest.URL description] isEqualToString:@"https://auth.jive.com/oauth2/verify"]) {
        [self verifyToken];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSError *error;
    NSDictionary *tokenData = [NSJSONSerialization JSONObjectWithData:receivedData options:kNilOptions error:&error];
    if ([tokenData objectForKey:@"access_token"]) {
        [self didReceiveAuthenticationToken:tokenData];
        [[NSNotificationCenter defaultCenter] postNotificationName:kAuthenticationFromTokenSucceeded object:nil];
        [webviewTimer invalidate];
        // if we received a new token, then close socket and restart
        //[[JCSocketDispatch sharedInstance] closeSocket];
        //[[JCSocketDispatch sharedInstance] requestSession];
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
                JCAppDelegate *delegate = (JCAppDelegate *)[UIApplication sharedApplication].delegate;
                if (![delegate.window.rootViewController isKindOfClass:[JCLoginViewController class]]) {
                    [delegate changeRootViewController:JCRootLoginViewController];
                }
                else {
                    [[NSNotificationCenter defaultCenter] postNotificationName:kAuthenticationFromTokenFailed object:nil];
                }
            }
        }
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
    //[webview stopLoading];
    [[NSNotificationCenter defaultCenter] postNotificationName:kAuthenticationFromTokenFailedWithTimeout object:kAuthenticationFromTokenFailedWithTimeout];
}
@end
