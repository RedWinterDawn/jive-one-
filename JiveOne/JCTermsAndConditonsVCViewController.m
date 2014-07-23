//
//  JCTermsAndConditonsVCViewController.m
//  JiveOne
//
//  Created by Doug on 4/30/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCTermsAndConditonsVCViewController.h"
#import "JCStyleKit.h"

@interface JCTermsAndConditonsVCViewController ()
@property (weak, nonatomic) IBOutlet UIWebView *webView;

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
//    [[NSURLCache sharedURLCache] removeCachedResponseForRequest:urlRequest];
    [self.webView loadRequest:urlRequest];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

@end
