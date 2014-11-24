//
//  JCAuthenticationManager.m
//  JiveAppOne
//
//  Created by Eduardo Gueiros on 2/8/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCAuthenticationManager.h"
#import "Common.h"

#import "KeychainItemWrapper.h"
#import "JCV5ApiClient.h"
#import "JCV4ProvisioningClient.h"
#import "JCAuthenticationManagerError.h"

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
    int _loginAttempts;
    
    KeychainItemWrapper *_keychainWrapper;
    CompletionBlock _completionBlock;
    
    NSString *_username;
    NSString *_password;
    UIWebView *_webview;
    
    NSTimer *_timeoutTimer;
}

@property (nonatomic, readwrite) NSString *jiveUserId;
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
    _loginAttempts = 0;
    
    username = [username stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    password = [password stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    // Validation
    if(username.length == 0 || password.length == 0){
        [self reportError:InvalidAuthenticationParameters description:@"UserName/Password Cannot Be Empty"];
        return;
    }
    
    [[JCOmniPresence sharedInstance] truncateAllTablesAtLogout];
    
    _username = username;
    _password = password;
    
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
    
//    dispatch_async(dispatch_get_main_queue(), ^{
//        _timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:80
//                                                         target:self
//                                                       selector:@selector(loginTimeout)
//                                                       userInfo:nil
//                                                        repeats:NO];
//     
//        [[NSRunLoop currentRunLoop] addTimer:_timeoutTimer forMode:NSDefaultRunLoopMode];
//     });
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
        self.jiveUserId = false;
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

-(void)setJiveUserId:(NSString *)userName
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

-(NSString *)jiveUserId
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:kUserName];
}

-(PBX *)pbx
{
    // TODO: When we are able to handle multiple PBX's return selected PBX, until then, returh the first.
    
    return [PBX MR_findFirst];
}

-(LineConfiguration *)lineConfiguration
{
    // TODO: When we are able to handle multiple Line configurations return selected Line configuration, until then, returh the first.
    
    return [LineConfiguration MR_findFirst];
}

-(NSString *)pbxName
{
    PBX *pbx = self.pbx;
    if (pbx)
        return [NSString stringWithFormat:@"%@ PBX on %@", pbx.name, [pbx.v5 boolValue] ? @"V5" : @"V4"];
    return nil;
}

#pragma mark - Private -

//- (void)loginTimeout
//{
//    [self reportError:TimeoutError description:@"This is taking longer than expected. Please check your connection and try again"];
//}

-(void)receivedAccessTokenFromURL:(NSURL *)url
{
    NSDictionary *tokenData = [self tokenDataFromURL:url];
    if (tokenData.count > 0)
    {
        if ([tokenData objectForKey:@"access_token"]) {
            self.authToken      = tokenData[@"access_token"];
            self.refreshToken   = tokenData[@"refresh_token"];
            self.jiveUserId       = tokenData[@"username"];
            self.userAuthenticated = true;
            [self requestAccount];
        }
        else {
            if (tokenData[@"error"]) {
                [self reportError:AutheticationError description:tokenData[@"error"]];
            }
            else {
                [self reportError:AutheticationError description:@"An Error Has Occurred, Please Try Again"];
            }
        }
    }
}

-(void)requestAccount
{
    NSString *jiveId = self.jiveUserId;
    [[JCV5ApiClient sharedClient] getMailboxReferencesForUser:jiveId completed:^(BOOL success, id responseObject, AFHTTPRequestOperation *operation, NSError *error) {
        if(success){
            NSArray *pbxs = [PBX MR_findAll];
            if (pbxs.count == 0) {
                [self reportError:NoPbx description:@"This username is not associated with any PBX. Please contact your Administrator"];
            }
            else if (pbxs.count > 1) {
                [self reportError:MultiplePbx description:@"This app does not support account with multiple PBXs at this time"];
            }
            else {
                [self requestProvisioning];
            }
        }
        else {
            [self reportError:NetworkError description:@"We could not reach the server at this time. Please check your connection"];
        }
    }];
}

- (void)requestProvisioning
{
    [JCV4ProvisioningClient requestProvisioningForUser:_username password:_password completed:^(BOOL success, NSError *error) {
        if (success) {
            self.userLoadedMininumData = TRUE;
        }
        else {
            [self reportError:ProvisioningFailure description:error.localizedFailureReason];
        }
    }];
}

-(void)reportError:(JCAuthenticationManagerErrorType)type description:(NSString *)description
{
    NSError *error = [JCAuthenticationManagerError errorWithType:type description:description];
    [self completionBlock:false error:error];
    _loginAttempts = 0;
    _webview = nil;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kJCAuthenticationManagerAuthenticationFailedNotification object:nil];
}

-(void)reportSuccess
{
    [self completionBlock:YES error:nil];
    self.userAuthenticated = TRUE;
    
    _webview = nil;
}

-(void)completionBlock:(BOOL)success error:(NSError *)error
{
    if (_completionBlock) {
        _completionBlock(success, error);
    }
    _completionBlock = nil;
}

//- (void)invalidateLoginTimeoutTimer
//{
//    dispatch_async(dispatch_get_main_queue(), ^{
//        if (_timeoutTimer) {
//            [_timeoutTimer invalidate];
//            _timeoutTimer = nil;
//        }
//    });
//}

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

#pragma mark - Delegate Handlers -

#pragma mark UIWebviewDelegate

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    if (_loginAttempts < MAX_LOGIN_ATTEMPTS) {
        NSString *javascript = [NSString stringWithFormat:kJCAuthenticationManagerJavascriptString, _username, _password];
        [webView stringByEvaluatingJavaScriptFromString:javascript];
        _loginAttempts++;
    }
    else {
        [webView stopLoading];
        [self reportError:InvalidAuthenticationParameters description:@"Invalid Username/Password. Please try again."];
    }
}

- (BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType
{
    #if DEBUG
        NSLog(@"%@", [request description]);
    #endif
    
    if ([request.URL.scheme isEqualToString:@"jiveclient"]) {
        [self receivedAccessTokenFromURL:request.URL];
        return NO;
    }
    return YES;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    if (self.userAuthenticated)
        return;
    
    [self reportError:NetworkError description:@"An Error Has Occurred, Please Try Again"];
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
