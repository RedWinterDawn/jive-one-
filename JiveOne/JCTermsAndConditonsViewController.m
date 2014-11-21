//
//  JCTermsAndConditonsVCViewController.m
//  JiveOne
//
//  Created by Doug on 4/30/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCTermsAndConditonsViewController.h"

NSString *const kJCTermsAndConditionsViewControllerURL = @"https://s3.amazonaws.com/jive.com-website/iOS+eula/%@.html";
NSString *const kJCTermsAndConditionsViewControllerEnglish = @"en";
NSString *const kJCTermsAndConditionsViewControllerMexicoSpanish = @"es-MX";
NSString *const kJCTermsAndConditionsViewControllerSpanish = @"es";

@implementation JCTermsAndConditonsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Jive Mobile EULA", @"Terms and Conditions EULA title");
    
    NSString *urlString = [NSString stringWithFormat:kJCTermsAndConditionsViewControllerURL, self.langauageCode];
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    [[NSURLCache sharedURLCache] removeCachedResponseForRequest:urlRequest];
    [self.webView loadRequest:urlRequest];
}

- (IBAction)backButtonPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
}

-(NSString *)langauageCode
{
    NSString *language = [[NSLocale preferredLanguages] objectAtIndex:0];
    if ([language isEqualToString:kJCTermsAndConditionsViewControllerMexicoSpanish]) {
        return language;
    }
    else if ([language isEqualToString:kJCTermsAndConditionsViewControllerSpanish]) {
        return language;
    }
    return kJCTermsAndConditionsViewControllerEnglish;
}


#pragma mark - Delegate Handlers -

#pragma mark UIWebViewDelegate

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}
- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

@end
