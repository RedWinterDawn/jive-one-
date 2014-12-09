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

// Notifications
NSString *const kJCAuthenticationManagerUserLoggedOutNotification               = @"userLoggedOut";
NSString *const kJCAuthenticationManagerUserAuthenticatedNotification           = @"userAuthenticated";
NSString *const kJCAuthenticationManagerUserLoadedMinimumDataNotification       = @"userLoadedMinimumData";
NSString *const kJCAuthenticationManagerAuthenticationFailedNotification        = @"authenticationFailed";
NSString *const kJCAuthenticationManagerPbxChangedNotification                  = @"pbxChanged";
NSString *const kJCAuthenticationManagerLineConfigurationChangedNotification    = @"lineConfigurationChanged";

// Keychain
NSString *const kJCAuthenticationManagerKeychainStoreIdentifier             = @"keyjiveauthstore";

// KVO and NSUserDefaults Keys
NSString *const kJCAuthenticationManagerUserAutheticatedAttributeKey        = @"userAuthenticated";
NSString *const kJCAuthenticationManagerUserLoadedMinimumDataAttributeKey   = @"userLoadedMinimumData";
NSString *const kJCAuthenticationManagerRememberMeAttributeKey              = @"rememberMe";
NSString *const kJCAuthenticationManagerRefreshTokenAttributeKey            = @"refreshToken";
NSString *const kJCAuthenticationManagerJiveUserIdKey                       = @"jiveUserId";


// Javascript
NSString *const kJCAuthenticationManagerJavascriptString    = @"document.getElementById('username').value = '%@';document.getElementById('password').value = '%@';document.getElementById('go-button').click()";

// OAuth
NSString *const kJCAuthenticationManagerAccessTokenUrl      = @"https://auth.jive.com/oauth2/v2/grant?client_id=%@&response_type=token&scope=%@&redirect_uri=%@";
NSString *const kJCAuthenticationManagerRefreshTokenUrl     = @"https://auth.jive.com/oauth2/v2/token";
NSString *const kJCAuthenticationManagerScopeProfile        = @"contacts.v1.profile.read";
NSString *const kJCAuthenticationManagerRefreshTokenData    = @"refresh_token=%@&client_id=%@&redirect_uri=%@&grant_type=refresh_token";
NSString *const kJCAuthenticationManagerClientId            = @"f62d7f80-3749-11e3-9b37-542696d7c505";
NSString *const kJCAuthenticationManagerClientSecret        = @"enXabnU5KuVm4XRSWGkU";
NSString *const kJCAuthenticationManagerURLSchemeCallback   = @"jiveclient://token";

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
    
    PBX *_pbx;
    LineConfiguration *_lineConfiguration;
    
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

-(void)checkAuthenticationStatus
{
    if (!self.userAuthenticated || !self.userLoadedMininumData)
        [self logout];
    else
        self.userLoadedMininumData = TRUE;
}

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
    
    NSString *url_path = [NSString stringWithFormat:kJCAuthenticationManagerAccessTokenUrl, kJCAuthenticationManagerClientId, kJCAuthenticationManagerScopeProfile, kJCAuthenticationManagerURLSchemeCallback];
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
    self.lineConfiguration = nil;
    
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
    [defaults setBool:YES forKey:kJCAuthenticationManagerUserAutheticatedAttributeKey];
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
    [defaults setBool:userLoadedMininumData forKey:kJCAuthenticationManagerUserLoadedMinimumDataAttributeKey];
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
    [defaults setBool:remember forKey:kJCAuthenticationManagerRememberMeAttributeKey];
    [defaults synchronize];
    [self didChangeValueForKey:kJCAuthenticationManagerRememberMeAttributeKey];
}

-(void)setAuthToken:(NSString *)authToken
{
    [_keychainWrapper setObject:(__bridge id)kSecAttrAccessibleAlways forKey:(__bridge id)kSecAttrAccount];
    [_keychainWrapper setObject:(__bridge id)kSecAttrAccessibleAlways forKey:(__bridge id)kSecValueData];
    [_keychainWrapper setObject:[NSString stringWithFormat:@"%@", authToken] forKey:(__bridge id)(kSecAttrAccount)];
    [_keychainWrapper setObject:[NSString stringWithFormat:@"%@", authToken] forKey:(__bridge id)(kSecValueData)];
}

-(void)setRefreshToken:(NSString *)refreshToken
{
    [self willChangeValueForKey:kJCAuthenticationManagerRefreshTokenAttributeKey];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:refreshToken forKey:kJCAuthenticationManagerRefreshTokenAttributeKey];
    [defaults synchronize];
    [self didChangeValueForKey:kJCAuthenticationManagerRefreshTokenAttributeKey];
}

-(void)setJiveUserId:(NSString *)userName
{
    [self willChangeValueForKey:kJCAuthenticationManagerJiveUserIdKey];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:userName forKey:kJCAuthenticationManagerJiveUserIdKey];
    [defaults synchronize];
    [self didChangeValueForKey:kJCAuthenticationManagerJiveUserIdKey];
}

-(void)setPbx:(PBX *)pbx
{
    if (_pbx == pbx) {
        return;
    }
    
    [self willChangeValueForKey:NSStringFromSelector(@selector(pbx))];
    _pbx = pbx;
    [self didChangeValueForKey:NSStringFromSelector(@selector(pbx))];
    
    self.lineConfiguration = nil; // Blow away the current line configuration, it is now dirty.
    [[NSNotificationCenter defaultCenter] postNotificationName:kJCAuthenticationManagerPbxChangedNotification object:self];
}

-(void)setLineConfiguration:(LineConfiguration *)lineConfiguration
{
    // if its the same line configuration and that configuration is not nil, then we do no need to broadcast it.
    if (_lineConfiguration == lineConfiguration) {
        return;
    }
    
    [self willChangeValueForKey:NSStringFromSelector(@selector(lineConfiguration))];
    _lineConfiguration = lineConfiguration;
    [self didChangeValueForKey:NSStringFromSelector(@selector(lineConfiguration))];
    [[NSNotificationCenter defaultCenter] postNotificationName:kJCAuthenticationManagerLineConfigurationChangedNotification object:self];
}

#pragma mark - Getters -

- (BOOL)userAuthenticated
{
    return [[NSUserDefaults standardUserDefaults]  boolForKey:kJCAuthenticationManagerUserAutheticatedAttributeKey];
}

- (BOOL)userLoadedMininumData
{
    return [[NSUserDefaults standardUserDefaults]  boolForKey:kJCAuthenticationManagerUserLoadedMinimumDataAttributeKey];
}

- (BOOL)rememberMe
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:kJCAuthenticationManagerRememberMeAttributeKey];
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
    
    return token;
}

-(NSString *)refreshToken
{
    return [[NSUserDefaults standardUserDefaults] valueForKey:kJCAuthenticationManagerRefreshTokenAttributeKey];
}

-(NSString *)jiveUserId
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:kJCAuthenticationManagerJiveUserIdKey];
}

/**
 * Returns the active PBX configuration
 */
-(PBX *)pbx
{
    if (_pbx) {
        return _pbx;
    }
    
    _pbx = [PBX MR_findFirstByAttribute:@"active" withValue:@YES];
    if (_pbx) {
        return _pbx;
    }
    
    _pbx = [PBX MR_findFirstOrderedByAttribute:@"name" ascending:YES];
    return _pbx;
}

/**
 * Return the active line configuration. If there is no active line configuration, we ret the first line line 
 * configuration in the database sorted by the display name.
 */
-(LineConfiguration *)lineConfiguration
{
    if (_lineConfiguration)
        return _lineConfiguration;
    
    _lineConfiguration = [LineConfiguration MR_findFirstByAttribute:@"active" withValue:@YES];
    if (_lineConfiguration)
        return _lineConfiguration;
    
    _lineConfiguration = [LineConfiguration MR_findFirstOrderedByAttribute:@"display" ascending:YES];
    return _lineConfiguration;
}

-(NSString *)pbxName
{
    PBX *pbx = self.pbx;
    if (pbx)
        return [NSString stringWithFormat:@"%@ PBX on %@", pbx.name, pbx.isV5 ? @"V5" : @"V4"];
    return nil;
}

#pragma mark - Private -

//- (void)loginTimeout
//{
//    [self reportError:TimeoutError description:@"This is taking longer than expected. Please check your connection and try again"];
//}

-(void)receivedAccessTokenFromURL:(NSURL *)url
{
    [self recievedAccessTokenData:[self tokenDataFromURL:url]];
}

-(void)recievedAccessTokenData:(NSDictionary *)tokenData
{
    if (tokenData.count > 0)
    {
        if ([tokenData objectForKey:@"access_token"]) {
            self.authToken      = tokenData[@"access_token"];
            self.refreshToken   = tokenData[@"refresh_token"];
            self.jiveUserId     = tokenData[@"username"];
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
            else {
                [self requestV4Provisioning];
            }
        }
        else {
            [self reportError:NetworkError description:@"We could not reach the server at this time. Please check your connection"];
        }
    }];
}

- (void)requestV4Provisioning
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

#pragma mark - Token Refresh -

/*- (void)checkForTokenValidity
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
                //                    [self requestTokenRefresh];
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
}*/

- (void)requestTokenRefresh
{
    NSString *refreshToken = self.refreshToken;
    if (refreshToken.isEmpty) {
        return;
    }
    
    NSURL *url = [NSURL URLWithString:kJCAuthenticationManagerRefreshTokenUrl];
    NSString *data = [NSString stringWithFormat:kJCAuthenticationManagerRefreshTokenData, refreshToken, kJCAuthenticationManagerClientId, kJCAuthenticationManagerURLSchemeCallback];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[data dataUsingEncoding:NSUTF8StringEncoding]];
    NSString* basicAuth = [@"Basic " stringByAppendingString:[Common encodeStringToBase64:[NSString stringWithFormat:@"%@:%@", kJCAuthenticationManagerClientId, kJCAuthenticationManagerClientSecret]]];
    [request setValue:basicAuth forHTTPHeaderField:@"Authorization"];
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               if (data) {
                                   __autoreleasing NSError *dataError;
                                   NSDictionary *tokenData = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&dataError];
                                   if ([tokenData objectForKey:@"access_token"]) {
                                       [self recievedAccessTokenData:tokenData];
                                   }
                                   else {
                                       [self reportError:AutheticationError description:@"An Error Has Occurred, Please Try Again"];
                                   }
                               } else {
                                   [self reportError:NetworkError description:@"An Error Has Occurred, Please Try Again"];
                               }
                           }];
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


static JCAuthenticationManager *authenticationManager = nil;
static dispatch_once_t authenticationManagerOnceToken;

@implementation JCAuthenticationManager (Singleton)

+ (instancetype)sharedInstance
{
    dispatch_once(&authenticationManagerOnceToken, ^{
        authenticationManager = [[JCAuthenticationManager alloc] init];
    });
    return authenticationManager;
}

@end
