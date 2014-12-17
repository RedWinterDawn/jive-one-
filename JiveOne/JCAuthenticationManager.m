//
//  JCAuthenticationManager.m
//  JiveAppOne
//
//  Created by Eduardo Gueiros on 2/8/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCAuthenticationManager.h"
#import "JCAuthenticationStore.h"

#import "Common.h"

#import "JCV5ApiClient.h"
#import "JCV4ProvisioningClient.h"
#import "JCAuthenticationManagerError.h"
#import "User+Custom.h"
#import "PBX+Custom.h"

// Notifications
NSString *const kJCAuthenticationManagerUserLoggedOutNotification               = @"userLoggedOut";
NSString *const kJCAuthenticationManagerUserAuthenticatedNotification           = @"userAuthenticated";
NSString *const kJCAuthenticationManagerUserLoadedMinimumDataNotification       = @"userLoadedMinimumData";
NSString *const kJCAuthenticationManagerAuthenticationFailedNotification        = @"authenticationFailed";
NSString *const kJCAuthenticationManagerLineChangedNotification                 = @"lineChanged";

// KVO and NSUserDefaults Keys
NSString *const kJCAuthenticationManagerRememberMeAttributeKey  = @"rememberMe";
NSString *const kJCAuthenticationManagerJiveUserIdKey           = @"username";

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
    JCAuthenticationStore *_authenticationStore;
    
    NSInteger _loginAttempts;
    CompletionBlock _completionBlock;
    Line *_line;
    UIWebView *_webview;
    
    NSString *_username;
    NSString *_password;
}

@property (nonatomic, readwrite) NSString *rememberMeUser;

@end

@implementation JCAuthenticationManager

-(instancetype)init
{
    self = [super init];
    if (self) {
        _authenticationStore = [[JCAuthenticationStore alloc] init];
    }
    return self;
}

#pragma mark - Class methods

/**
 * Checks the authentication status of the user.
 *
 * Retrieves from the authentication store if the user has authenticated, and tries to load the user 
 * object using the user stored in the authenctication store.
 *
 */
-(void)checkAuthenticationStatus
{
    // Check to see if we are autheticiated. If we are not, notify that we are logged out.
    if (!_authenticationStore.isAuthenticated) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kJCAuthenticationManagerUserLoggedOutNotification object:self userInfo:nil];
        return;
    }
    
    // Check to see if we have data using the authentication store to retrive the user id.
    NSString *jiveUserId = _authenticationStore.jiveUserId;
    _user = [User MR_findFirstByAttribute:@"jiveUserId" withValue:jiveUserId];
    if (_user && _user.pbxs) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kJCAuthenticationManagerUserLoadedMinimumDataNotification object:self userInfo:nil];
    }
    else {
        [self logout]; // Nuke it, we need to relogin.
    }
}

- (void)loginWithUsername:(NSString *)username password:(NSString *)password completed:(CompletionBlock)completed
{
    _completionBlock = completed;
    _loginAttempts = 0;

    // Validation
    username = [username stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    password = [password stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if(username.length == 0 || password.length == 0){
        [self reportError:InvalidAuthenticationParameters description:@"UserName/Password Cannot Be Empty"];
        return;
    }
    _username = username;
    _password = password;
    
    // Clears stored credentials.
    [_authenticationStore logout];
    _user = nil;
    _line = nil;
           
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:kJCAuthenticationManagerAccessTokenUrl, kJCAuthenticationManagerClientId, kJCAuthenticationManagerScopeProfile, kJCAuthenticationManagerURLSchemeCallback]];
    
#if DEBUG
    [NSURLRequest setAllowsAnyHTTPSCertificate:YES forHost:url.host];
    NSLog(@"AUTH PATH: %@", url.absoluteString);
#endif
    
    if (!_webview) {
        _webview = [[UIWebView alloc] init];
    }
    _webview.delegate = self;
    [_webview loadRequest:[NSURLRequest requestWithURL:url]];
}

- (void)logout
{
    [_authenticationStore logout];
    _user = nil;
    _line = nil;
    if (!self.rememberMe) {
        self.rememberMeUser = nil;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:kJCAuthenticationManagerUserLoggedOutNotification object:self userInfo:nil];
}

#pragma mark - Setters -

-(void)setRememberMe:(BOOL)remember
{
    [self willChangeValueForKey:kJCAuthenticationManagerRememberMeAttributeKey];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:remember forKey:kJCAuthenticationManagerRememberMeAttributeKey];
    [defaults synchronize];
    [self didChangeValueForKey:kJCAuthenticationManagerRememberMeAttributeKey];
}

-(void)setRememberMeUser:(NSString *)rememberMeUser
{
    [self willChangeValueForKey:kJCAuthenticationManagerJiveUserIdKey];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:rememberMeUser forKey:kJCAuthenticationManagerJiveUserIdKey];
    [defaults synchronize];
    [self didChangeValueForKey:kJCAuthenticationManagerJiveUserIdKey];
}

-(void)setLine:(Line *)line
{
    if (_line == line) {
        return;
    }
    
    [self willChangeValueForKey:NSStringFromSelector(@selector(line))];
    _line = line;
    [self didChangeValueForKey:NSStringFromSelector(@selector(line))];
    [[NSNotificationCenter defaultCenter] postNotificationName:kJCAuthenticationManagerLineChangedNotification object:self];
}

#pragma mark - Getters -

- (BOOL)userAuthenticated
{
    return _authenticationStore.isAuthenticated;
}

- (BOOL)userLoadedMinimumData
{
    return (_user && _user.pbxs);
}

-(NSString *)authToken
{
    return _authenticationStore.accessToken;
}

-(NSString *)jiveUserId
{
    return _authenticationStore.jiveUserId;
}

- (BOOL)rememberMe
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:kJCAuthenticationManagerRememberMeAttributeKey];
}

-(NSString *)rememberMeUser
{
    return [[NSUserDefaults standardUserDefaults] valueForKey:kJCAuthenticationManagerJiveUserIdKey];
}

-(Line *)line
{
    if (_line) {
        return _line;
    }
    
    // If we do not have a user loaded, we cannot select the line.
    if (!_user) {
        return nil;
    }
    
    // If we do not yet have a line, look for a line for our user that is marked as active.
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"pbx.user = %@ and active = %@", _user, @YES];
    _line = [Line MR_findFirstWithPredicate:predicate];
    if (_line) {
        return _line;
    }
    
    predicate = [NSPredicate predicateWithFormat:@"pbx.user = %@", _user];
    _line = [Line MR_findFirstWithPredicate:predicate sortedBy:@"extension" ascending:YES];
    return _line;
}

#pragma mark - Private -

-(void)receivedAccessTokenData:(NSDictionary *)tokenData
{
    @try {
        if (!tokenData || tokenData.count < 1) {
            [NSException raise:NSInvalidArgumentException format:@"Token Data is NULL"];
        }
        
        if (tokenData[@"error"]) {
            [NSException raise:NSInvalidArgumentException format:@"%@", tokenData[@"error"]];
        }
        
        [_authenticationStore setAuthToken:tokenData];
        [[NSNotificationCenter defaultCenter] postNotificationName:kJCAuthenticationManagerUserAuthenticatedNotification object:self userInfo:nil];
        _user = [User userForJiveUserId:_authenticationStore.jiveUserId context:[NSManagedObjectContext MR_contextForCurrentThread]];
        
        if(self.rememberMe)
            self.rememberMeUser = _authenticationStore.jiveUserId;
        
        [PBX downloadPbxInfoForUser:_user completed:^(BOOL success, NSError *error) {
            if (success) {
                [self notifyCompletionBlock:YES error:nil];
            }
            else {
                NSLog(@"%@", [error description]);
                [self reportError:NetworkError description:@"We could not reach the server at this time. Please check your connection"];
            }
        }];
    }
    @catch (NSException *exception) {
        [self reportError:AutheticationError description:exception.reason];
    }
}

-(void)reportError:(JCAuthenticationManagerErrorType)type description:(NSString *)description
{
    [self notifyCompletionBlock:NO error:[JCAuthenticationManagerError errorWithType:type description:description]];
}

-(void)notifyCompletionBlock:(BOOL)success error:(NSError *)error
{
    _completionBlock = nil;
    _loginAttempts = 0;
    _webview = nil;
    _username = nil;
    _password = nil;
    _line = nil;
    
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    if (success){
        [center postNotificationName:kJCAuthenticationManagerUserLoadedMinimumDataNotification object:self userInfo:nil];
    } else {
        [self logout];
        [center postNotificationName:kJCAuthenticationManagerAuthenticationFailedNotification object:self userInfo:nil];
    }
    
    if (_completionBlock) {
        _completionBlock(success, error);
    }
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
    if ([request.URL.scheme isEqualToString:@"jiveclient"]) {
        [self receivedAccessTokenData:[self tokenDataFromURL:request.URL]];
        return NO;
    }
    return YES;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    if (_authenticationStore.isAuthenticated) {
        return;
    }
    [self reportError:NetworkError description:error.localizedDescription];
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

