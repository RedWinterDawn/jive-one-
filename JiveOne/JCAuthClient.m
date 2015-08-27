//
//  JCAuthClient.m
//  JiveOne
//
//  Created by P Leonard on 3/24/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCAuthClient.h"
#import "JCAuthClientError.h"

@import UIKit;

// Javascript
NSString *const kJCAuthClientJavascriptString    = @"document.getElementById('username').value = '%@';document.getElementById('password').value = '%@';document.getElementById('go-button').click()";

// OAuth
NSString *const kJCAuthClientAccessTokenUrl     = @"https://auth.jive.com/oauth2/v2/grant?client_id=%@&response_type=token&scope=%@&redirect_uri=%@";
NSString *const kJCAuthClientRefreshTokenUrl    = @"https://auth.jive.com/oauth2/v2/token";
NSString *const kJCAuthClientScopeProfile       = @"contacts.v1.profile.read%20sms.v1.send%20jasmine.v2.subscribe";
NSString *const kJCAuthClientRefreshTokenData   = @"refresh_token=%@&client_id=%@&redirect_uri=%@&grant_type=refresh_token";
NSString *const kJCAuthClientClientId           = @"f62d7f80-3749-11e3-9b37-542696d7c505";
NSString *const kJCAuthClientClientSecret       = @"enXabnU5KuVm4XRSWGkU";
NSString *const kJCAuthClientURLSchemeCallback  = @"jiveclient://token";

#define MAX_LOGIN_ATTEMPTS 2

#if DEBUG
@interface NSURLRequest(Private)
+(void)setAllowsAnyHTTPSCertificate:(BOOL)inAllow forHost:(NSString *)inHost;
@end
#endif

@interface JCAuthClient () <UIWebViewDelegate>
{
    NSInteger _loginAttempts;
    JCAuthClientLoginCompletionBlock _completionBlock;
    UIWebView *_webview;
    NSString *_username;
    NSString *_password;
}

@end

@implementation JCAuthClient

-(instancetype)init
{
    self = [super init];
    if (self) {
        _maxloginAttempts = MAX_LOGIN_ATTEMPTS;
    }
    return self;
}

#pragma mark - Class methods

- (void)loginWithUsername:(NSString *)username password:(NSString *)password completion:(JCAuthClientLoginCompletionBlock)completion
{
    _completionBlock = completion;
    _loginAttempts = 0;
    
    // Validation
    username = [username stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    password = [password stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if(username.length == 0 || password.length == 0){
        [self reportError:[JCAuthClientError errorWithCode:AUTH_CLIENT_INVALID_REQUEST_PARAMETERS]];
        return;
    }
    
    _username = username;
    _password = password;
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:kJCAuthClientAccessTokenUrl, kJCAuthClientClientId, kJCAuthClientScopeProfile, kJCAuthClientURLSchemeCallback]];
    
#if DEBUG
    [NSURLRequest setAllowsAnyHTTPSCertificate:YES forHost:url.host];
#endif
    
    if (!_webview) {
        _webview = [[UIWebView alloc] init];
    }
    _webview.delegate = self;
    [_webview loadRequest:[NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:10]];
}

-(void)reportError:(JCAuthClientError *)error
{
    [self notifyCompletionBlock:NO authToken:nil error:error];
}

-(void)notifyCompletionBlock:(BOOL)success authToken:(JCAuthInfo *)authInfo error:(NSError *)error
{
    _loginAttempts = 0;
    _webview    = nil;
    _username   = nil;
    _password   = nil;
    
    if (_completionBlock) {
        _completionBlock(success, authInfo, error);
        _completionBlock = nil;
    }
}

#pragma mark - Delegate Handlers -

#pragma mark UIWebviewDelegate

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    if (_loginAttempts < _maxloginAttempts) {
        NSString *javascript = [NSString stringWithFormat:kJCAuthClientJavascriptString, _username, _password];
        [webView stringByEvaluatingJavaScriptFromString:javascript];
        _loginAttempts++;
    }
    else {
        [webView stopLoading];
        [self reportError:[JCAuthClientError errorWithCode:AUTH_CLIENT_AUTHENTICATION_ERROR]];
    }
}

- (BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if ([request.URL.scheme isEqualToString:@"jiveclient"]) {
        JCAuthInfo *authInfo = [[JCAuthInfo alloc] initWithUrl:request.URL];
        [self notifyCompletionBlock:YES authToken:authInfo error:nil];
        return NO;
    }
    return YES;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    if (!_completionBlock) {
        return;
    }
    [self reportError:[JCAuthClientError errorWithCode:AUTH_CLIENT_NETWORK_ERROR underlyingError:error]];
}

@end



