//
//  JCSettingsTableViewController.m
//  JiveOne
//
//  Created by Robert Barclay on 11/19/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCSettingsTableViewController.h"

#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>

#import "JCTermsAndConditonsVCViewController.h"

#import "JCAuthenticationManager.h"
#import "JCLogoutIcon.h"

NSString *const kJCSettingsTableViewControllerFeebackMessage = @"<strong>Description of feedback:</strong> <br><br><br><br><br><hr><strong>Device Specs</strong><br>Model: %@ <br> System Version: %@ <br> App Version: %@ <br> Country: %@";

@interface JCSettingsTableViewController () <MFMailComposeViewControllerDelegate>
{
    JCAuthenticationManager *_authenticationManager;
}

@end

@implementation JCSettingsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _authenticationManager = [JCAuthenticationManager sharedInstance];
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    JCLogoutIcon *icon = [[JCLogoutIcon alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    icon.backgroundColor = [UIColor redColor];
    [self.logoutCell setAccessoryView:icon];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.view setNeedsLayout];
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    self.userNameLabel.text     = _authenticationManager.userName;
    self.nameLabel.text         = _authenticationManager.lineDisplayName;
    self.extensionLabel.text    = _authenticationManager.lineExtension;
    self.pbxLabel.text          = _authenticationManager.pbxName;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    UIViewController *controller = segue.destinationViewController;
    if ([controller isKindOfClass:[JCTermsAndConditonsVCViewController class]]) {
        controller.navigationItem.leftBarButtonItem = nil;
    }
}

#pragma mark - IBActions -

-(IBAction)leaveFeedback:(id)sender
{
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *mailViewController = [[MFMailComposeViewController alloc] init];
        mailViewController.mailComposeDelegate = self;
        [mailViewController setToRecipients:[NSArray arrayWithObject:kFeedbackEmail]];
        [mailViewController setSubject:@"Feedback"];
        
        //get device specs
        UIDevice *currentDevice = [UIDevice currentDevice];
        NSString *model         = [currentDevice model];
        NSString *systemVersion = [currentDevice systemVersion];
        NSString *appVersion    = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
        NSString *country       = [[NSLocale currentLocale] localeIdentifier];
        
        NSString *bodyTemplate = [NSString stringWithFormat:kJCSettingsTableViewControllerFeebackMessage, model, systemVersion, appVersion, country];
        [mailViewController setMessageBody:bodyTemplate isHTML:YES];
        [self presentViewController:mailViewController animated:YES completion:nil];
    }
}

-(IBAction)logout:(id)sender
{
    [_authenticationManager logout];
}

#pragma mark - Delegate Handlers -

#pragma mark MFMailComposeViewControllerDelegate

-(void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
