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
NSString *const kJCAuthenticationManagerAuthenticationFailedNotification = @"authenticationFailed";

// Javascript
NSString *const kJCAuthenticationManagerJavascriptString = @"document.getElementById('username').value = '%@';document.getElementById('password').value = '%@';document.getElementById('go-button').click()";


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
    
    if (!_webview) {
        _webview = [[UIWebView alloc] init];
    }
    _webview.delegate = self;
    [_webview loadRequest:[NSURLRequest requestWithURL:url]];
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

-(void)reportError:(NSString *)string
{
    [self sendCompletionBlock:false reason:string];
    loginAttempts = 0;
    _webview = nil;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kJCAuthenticationManagerAuthenticationFailedNotification object:nil];
}

-(void)reportSuccess
{
    [self sendCompletionBlock:YES reason:nil];
    self.userAuthenticated = TRUE;
    _webview = nil;
}

-(void)sendCompletionBlock:(BOOL)success reason:(NSString *)reason
{
    NSError *error = nil;
    if (reason){
        error = [NSError errorWithDomain:@"auth" code:500 userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(reason, nil)}];
    }
    
    if (_completionBlock) {
        _completionBlock(success, error);
    }
    _completionBlock = nil;
}

-(NSDictionary *)tokenDataFromURL:(NSURL *)url
{
    NSString *stringURL = [url description];
    NSArray *topLevel =  [stringURL componentsSeparatedByString:@"#"];
    NSArray *urlParams = [topLevel[1] componentsSeparatedByString:@"&"];
    
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    for (NSString *param in urlParams)
    {
        NSArray *keyValue = [param componentsSeparatedByString:@"="];
        NSString *key = [keyValue objectAtIndex:0];
        NSString *value = [keyValue objectAtIndex:1];
        [data setObject:value forKey:key];
    }
    
    return data;
}

-(void)receivedAccessTokenFromURL:(NSURL *)url
{
    NSDictionary *tokenData = [self tokenDataFromURL:url];
    if (tokenData && tokenData.count > 0)
    {
        if ([tokenData objectForKey:@"access_token"]) {
            self.authToken      = tokenData[@"access_token"];
            self.refreshToken   = tokenData[@"refresh_token"];
            self.userName       = tokenData[@"username"];
            [self reportSuccess];
        }
        else {
            if (tokenData[@"error"]) {
                [self reportError:tokenData[@"error"]];
            }
            else {
                [self reportError:@"An Error Has Occurred, Please Try Again"];
            }
        }
    }
}

#pragma mark - Delegate Handlers -

#pragma mark UIWebviewDelegate

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    if (loginAttempts < MAX_LOGIN_ATTEMPTS) {
        NSString *javascript = [NSString stringWithFormat:kJCAuthenticationManagerJavascriptString, _username, _password];
        [webView stringByEvaluatingJavaScriptFromString:javascript];
        loginAttempts++;
    }
    else {
        [webView stopLoading];
        
        [self reportError:@"Invalid Username/Password. Please try again."];
    }
}

- (BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType
{
    #if DEBUG
        NSLog(@"%@", [request description]);
    #endif
    
    if ([request.URL.scheme isEqualToString:@"jiveclient"]) {
        [self receivedAccessTokenFromURL:request.URL];
    }
    return YES;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [self reportError:@"An Error Has Occurred, Please Try Again"];
}

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
