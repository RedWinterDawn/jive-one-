//
//  JCAuthenticationManager.m
//  JiveAppOne
//
//  Created by Eduardo Gueiros on 2/8/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCAuthenticationManager.h"
#import "JCAuthenticationKeychain.h"

#import "Common.h"

#import "JCV5ApiClient.h"
#import "JCAuthenticationManagerError.h"
#import "User+Custom.h"
#import "PBX+V5Client.h"

// Notifications
NSString *const kJCAuthenticationManagerUserLoggedOutNotification               = @"userLoggedOut";
NSString *const kJCAuthenticationManagerUserAuthenticatedNotification           = @"userAuthenticated";
NSString *const kJCAuthenticationManagerUserLoadedMinimumDataNotification       = @"userLoadedMinimumData";
NSString *const kJCAuthenticationManagerAuthenticationFailedNotification        = @"authenticationFailed";
NSString *const kJCAuthenticationManagerLineChangedNotification                 = @"lineChanged";

// KVO and NSUserDefaults Keys
NSString *const kJCAuthenticationManagerRememberMeAttributeKey  = @"rememberMe";
NSString *const kJCAuthenticationManagerJiveUserIdKey           = @"username";

NSString *const kJCAuthenticationManagerAccessTokenKey  = @"access_token";
NSString *const kJCAuthenticationManagerRefreshTokenKey = @"refresh_token";
NSString *const kJCAuthenticationManagerUsernameKey     = @"username";
NSString *const kJCAuthenticationManagerRememberMeKey   = @"remberMe";


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
    JCAuthenticationKeychain *_authenticationKeychain;
    
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
        _authenticationKeychain = [[JCAuthenticationKeychain alloc] init];
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
    if (!_authenticationKeychain.isAuthenticated) {
        [self postNotificationEvent:kJCAuthenticationManagerUserLoggedOutNotification];
        return;
    }

    // Check to see if we have data using the authentication store to retrive the user id.
    NSString *jiveUserId = _authenticationKeychain.jiveUserId;
    _user = [User MR_findFirstByAttribute:NSStringFromSelector(@selector(jiveUserId)) withValue:jiveUserId];
    if (_user && _user.pbxs.count > 0) {
        [self postNotificationEvent:kJCAuthenticationManagerUserLoadedMinimumDataNotification];
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
        [self reportError:JCAuthenticationManagerInvalidParameterError description:@"Username/Password Cannot Be Empty"];
        return;
    }
    
    [_authenticationKeychain logout]; // destroy current authToken;
    _username = username;
    _password = password;
    
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
    [_authenticationKeychain logout];
    _user = nil;
    _line = nil;
    if (!self.rememberMe) {
        self.rememberMeUser = nil;
    }
    
    [self postNotificationEvent:kJCAuthenticationManagerUserLoggedOutNotification];
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
    [self willChangeValueForKey:NSStringFromSelector(@selector(line))];
    _line = line;
    [self didChangeValueForKey:NSStringFromSelector(@selector(line))];
    [self postNotificationEvent:kJCAuthenticationManagerLineChangedNotification];
}

- (void)setDeviceToken:(NSString *)deviceToken
{
    NSString *newToken = [deviceToken description];
    newToken = [newToken stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    newToken = [newToken stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue:newToken forKey:UDdeviceToken];
    [defaults synchronize];
}

#pragma mark - Getters -

- (BOOL)userAuthenticated
{
    return _authenticationKeychain.isAuthenticated;
}

- (BOOL)userLoadedMinimumData
{
    return (_user && _user.pbxs);
}

-(NSString *)authToken
{
    return _authenticationKeychain.accessToken;
}

-(NSString *)jiveUserId
{
    return _authenticationKeychain.jiveUserId;
}

-(NSString *)deviceToken
{
    return [[NSUserDefaults standardUserDefaults] valueForKey:UDdeviceToken];
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
        
        NSString *accessToken = [tokenData valueForKey:kJCAuthenticationManagerAccessTokenKey];
        if (!accessToken || accessToken.length == 0) {
            [NSException raise:NSInvalidArgumentException format:@"Access Token null or empty"];
        }
        
        NSString *jiveUserId = [tokenData valueForKey:kJCAuthenticationManagerUsernameKey];
        if (!jiveUserId || jiveUserId.length == 0) {
            [NSException raise:NSInvalidArgumentException format:@"Username null or empty"];
        }
        
        if (![jiveUserId isEqualToString:_username]) {
           [NSException raise:NSInvalidArgumentException format:@"Auth token user name does not match login user name"];
        }
        
        if (![_authenticationKeychain setAccessToken:accessToken username:jiveUserId]) {
            [NSException raise:NSInvalidArgumentException format:@"Unable to save access token to keychain store."];
        }
        
        if(self.rememberMe)
            self.rememberMeUser = jiveUserId;
        
        // Broadcast that we have authenticated.
        [self postNotificationEvent:kJCAuthenticationManagerUserAuthenticatedNotification];
        
        NSManagedObjectContext *context = [NSManagedObjectContext MR_contextForCurrentThread];
        _user = [User userForJiveUserId:_authenticationKeychain.jiveUserId context:context];
        [self fetchPbxInfoForUser:_user];
        
    }
    @catch (NSException *exception) {
        [self reportError:JCAuthenticationManagerAutheticationError description:exception.reason];
    }
}

-(void)fetchPbxInfoForUser:(User *)user
{
    dispatch_async(dispatch_queue_create("pbx_info", 0), ^{
        [PBX downloadPbxInfoForUser:(User *)[[NSManagedObjectContext MR_contextForCurrentThread] objectWithID:user.objectID]
                          completed:^(BOOL success, NSError *error) {
                              dispatch_async(dispatch_get_main_queue(), ^{
                                  if (success) {
                                      [self notifyCompletionBlock:YES error:nil];
                                  }
                                  else {
                                      [self reportError:JCAuthenticationManagerNetworkError description:@"We could not reach the server at this time. Please check your connection"];
                                  }
                              });
                          }];
    });
}

-(void)reportError:(JCAuthenticationManagerErrorType)type description:(NSString *)description
{
    [self notifyCompletionBlock:NO error:[JCAuthenticationManagerError errorWithType:type description:description]];
}

-(void)notifyCompletionBlock:(BOOL)success error:(NSError *)error
{
    _loginAttempts = 0;
    _webview    = nil;
    _username   = nil;
    _password   = nil;
    _line       = nil;
    
    if (success){
        [self postNotificationEvent:kJCAuthenticationManagerUserLoadedMinimumDataNotification];
    } else {
        [_authenticationKeychain logout];
        [self postNotificationEvent:kJCAuthenticationManagerAuthenticationFailedNotification];
    }
    
    if (_completionBlock) {
        _completionBlock(success, error);
        _completionBlock = nil;
    }
}

/**
 * A helper method to post a notification to the main thread. All notifcations posting from the
 * authentication Manager should be from the main thread.
 */
-(void)postNotificationEvent:(NSString *)event
{
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(postNotificationEvent:) withObject:event waitUntilDone:NO];
        return;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:event object:self userInfo:nil];
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
        [self reportError:JCAuthenticationManagerInvalidParameterError description:@"Invalid Username/Password.\nPlease try again."];
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
    if (_authenticationKeychain.isAuthenticated) {
        return;
    }
    [self reportError:JCAuthenticationManagerNetworkError description:error.localizedDescription];
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

