//
//  JCAuthClient.m
//  JiveOne
//
//  Created by P Leonard on 3/24/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCAuthClient.h"
#import "JCAuthClientError.h"

// Javascript
NSString *const kJCAuthClientJavascriptString    = @"document.getElementById('username').value = '%@';document.getElementById('password').value = '%@';document.getElementById('go-button').click()";

// OAuth
NSString *const kJCAuthClientAccessTokenUrl           = @"https://auth.jive.com/oauth2/v2/grant?client_id=%@&response_type=token&scope=%@&redirect_uri=%@";
NSString *const kJCAuthClientRefreshTokenUrl          = @"https://auth.jive.com/oauth2/v2/token";
NSString *const kJCAuthClientScopeProfile                 = @"contacts.v1.profile.read%20sms.v1.send";
NSString *const kJCAuthClientRefreshTokenData     = @"refresh_token=%@&client_id=%@&redirect_uri=%@&grant_type=refresh_token";
NSString *const kJCAuthClientClientId                     = @"f62d7f80-3749-11e3-9b37-542696d7c505";
NSString *const kJCAuthClientClientSecret        = @"enXabnU5KuVm4XRSWGkU";
NSString *const kJCAuthClientURLSchemeCallback   = @"jiveclient://token";


#if DEBUG
@interface NSURLRequest(Private)
+(void)setAllowsAnyHTTPSCertificate:(BOOL)inAllow forHost:(NSString *)inHost;
@end
#endif
@interface JCAuthClient () <UIWebViewDelegate>
{
    NSInteger _loginAttempts;
    CompletionBlock _completionBlock;
    UIWebView *_webview;
    
    NSString *_username;
    NSString *_password;
}

@end

@implementation JCAuthClient

#pragma mark - Class methods

- (void)loginWithUsername:(NSString *)username password:(NSString *)password completed:(CompletionBlock)completed
{
    _completionBlock = completed;
    _loginAttempts = 0;
    
    // Validation
    username = [username stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    password = [password stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if(username.length == 0 || password.length == 0){
        [JCAuthClientError errorWithCode:1006];
        //TODO: actually report error here
        return;
    }
    
    _username = username;
    _password = password;
    
    _user = nil;
    _line = nil;
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:kJCAuthClientAccessTokenUrl, kJCAuthClientClientId, kJCAuthClientScopeProfile, kJCAuthClientURLSchemeCallback]];
    
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

-(void)notifyCompletionBlock:(BOOL)success error:(NSError *)error
{
    _loginAttempts = 0;
    _webview    = nil;
    _username   = nil;
    _password   = nil;
    _line       = nil;
    
    if (_completionBlock) {
        _completionBlock(success, error);
        _completionBlock = nil;
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
@end



