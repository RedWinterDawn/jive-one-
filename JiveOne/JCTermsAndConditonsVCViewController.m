//
//  JCTermsAndConditonsVCViewController.m
//  JiveOne
//
//  Created by Doug on 4/30/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCTermsAndConditonsVCViewController.h"
#import "JCStyleKit.h"
#import <QuartzCore/QuartzCore.h>
#import "Common.h"

@interface JCTermsAndConditonsVCViewController ()
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *backButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *forwardButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *refreshButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *actionButton;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
- (IBAction)OpenLinkInBrowser:(id)sender;

@end

@implementation JCTermsAndConditonsVCViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
//    [[UINavigationBar appearance] setBarTintColor:[UIColor blackColor]];
    // Do any additional setup after loading the view.
    NSURL *websiteUrl = [NSURL URLWithString:kEulaSite];

    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:websiteUrl];
    [[NSURLCache sharedURLCache] removeCachedResponseForRequest:urlRequest];
	self.webView.delegate = self;
    [self.webView loadRequest:urlRequest];
	
//	UIImage *backImage = [UIImage imageNamed:@"arrow-back"];
//	UIImage *forwardImage = [UIImage imageWithCGImage:backImage.CGImage scale:backImage.scale orientation:UIImageOrientationDown];
//
//	UIImageView *backView = [[UIImageView alloc] initWithImage:backImage];
//	UIImageView *forwardView = [[UIImageView alloc] initWithImage:forwardImage];
//	
//	backView.frame = CGRectInset(backView.frame, 50, 50);
//	forwardView.frame = CGRectInset(forwardView.frame, 50, 50);
//	
//	[self.backButton setCustomView:backView];
//	[self.forwardButton setCustomView:forwardView];
	
	
	
    
}

- (void)updateButtons
{
	self.forwardButton.enabled = self.webView.canGoForward;
	self.backButton.enabled = self.webView.canGoBack;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [self updateButtons];
}
- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self updateButtons];
}
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self updateButtons];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
- (IBAction)backButtonPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
        [[NSURLCache sharedURLCache] removeAllCachedResponses];
}

- (IBAction)OpenLinkInBrowser:(id)sender {
	
	UIActionSheet *popUp = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Open in Safari", nil];
	
	[popUp showInView:[UIApplication sharedApplication].keyWindow];
}

#pragma mark - Actionsheet delegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	switch (buttonIndex) {
		case 0:
			[[UIApplication sharedApplication] openURL:[NSURL URLWithString:kEulaSite]];
			break;
			
		default:
			break;
	}
}
@end
