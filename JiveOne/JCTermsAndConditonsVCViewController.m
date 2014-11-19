//
//  JCTermsAndConditonsVCViewController.m
//  JiveOne
//
//  Created by Doug on 4/30/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCTermsAndConditonsVCViewController.h"

@implementation JCTermsAndConditonsVCViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Jive Mobile EULA", @"Terms and Conditions EULA title");
    
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:kEulaSite]];
    [[NSURLCache sharedURLCache] removeCachedResponseForRequest:urlRequest];
    [self.webView loadRequest:urlRequest];
}

- (IBAction)backButtonPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
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
