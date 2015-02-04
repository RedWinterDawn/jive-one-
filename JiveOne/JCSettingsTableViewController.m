//
//  JCSettingsTableViewController.m
//  JiveOne
//
//  Created by Robert Barclay on 11/19/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCSettingsTableViewController.h"
#import "JCPhoneManager.h"
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>
#import "JCTermsAndConditonsViewController.h"
#import "JCAuthenticationManager.h"
#import "JCAppSettings.h"

#import "PBX.h"

NSString *const kJCSettingsTableViewControllerFeebackMessage = @"<strong>Please describe any issues you are experiencing :</strong><br><br><br><br><br><br><br><br><br><br><br><br><br><hr><strong>Device Specs</strong><br>Model: %@ <br> On iOS Version: %@ <br> App Version: %@ <br> Country: %@ <br> UUID : %@  <br> PBX : %@  <br> User : %@  <br> Line : %@  <br> ";

@interface JCSettingsTableViewController () <MFMailComposeViewControllerDelegate>
{
    JCAuthenticationManager *_authenticationManager;
    JCPhoneManager * _phoneManager;
}

@end

@implementation JCSettingsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _authenticationManager = [JCAuthenticationManager sharedInstance];
    _phoneManager = [JCPhoneManager sharedManager];
    
    NSBundle *bundle = [NSBundle mainBundle];
    self.appLabel.text = [bundle objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    self.buildLabel.text = [bundle objectForInfoDictionaryKey:@"CFBundleVersion"];
    
    JCAppSettings *settings = [JCAppSettings sharedSettings];
    self.wifiOnly.on = settings.wifiOnly;
    self.presenceEnabled.on = settings.presenceEnabled;
}

-(void)awakeFromNib
{
    [super awakeFromNib];
    
    #ifndef DEBUG
    self.navigationItem.rightBarButtonItem = nil;
    #endif
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
    
    self.userNameLabel.text     = _authenticationManager.line.pbx.user.jiveUserId;
    self.extensionLabel.text    = _authenticationManager.line.extension;
    if ([JCAuthenticationManager sharedInstance].line.pbx.isV5) {
        self.enablePreasenceCell.hidden = false;
    } else
        self.enablePreasenceCell.hidden = true;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    UIViewController *controller = segue.destinationViewController;
    if ([controller isKindOfClass:[JCTermsAndConditonsViewController class]]) {
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
        UIDevice *currentDevice     = [UIDevice currentDevice];
        NSString *model             = [currentDevice platformType];
        NSString *systemVersion     = [currentDevice systemVersion];
        NSString *appVersion        = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
        NSString *country           = [[NSLocale currentLocale] localeIdentifier];
        NSString *uuid              = [currentDevice userUniqueIdentiferForUser:_authenticationManager.jiveUserId];
        NSString * pbx              = _authenticationManager.line.pbx.displayName;
        NSString *user              = _authenticationManager.line.pbx.user.jiveUserId;
        NSString *line              = _authenticationManager.line.extension;
        
        NSString *bodyTemplate = [NSString stringWithFormat:kJCSettingsTableViewControllerFeebackMessage, model, systemVersion, appVersion, country, uuid, pbx, user, line];
        [mailViewController setMessageBody:bodyTemplate isHTML:YES];
        [self presentViewController:mailViewController animated:YES completion:nil];
    }
}

-(IBAction)logout:(id)sender
{
    [_authenticationManager logout];
}

-(IBAction)toggleWifiOnly:(id)sender
{
    if ([sender isKindOfClass:[UISwitch class]]) {
        UISwitch *switchBtn = (UISwitch *)sender;
        JCAppSettings *settings = [JCAppSettings sharedSettings];
        settings.wifiOnly = !settings.isWifiOnly;
        switchBtn.on = settings.isWifiOnly;
        [JCPhoneManager connectToLine:_authenticationManager.line];
    }
}

- (IBAction)togglePresenceEnabled:(id)sender {
    if ([sender isKindOfClass:[UISwitch class]]) {
        UISwitch *switchBtn = (UISwitch *)sender;
        JCAppSettings *settings = [JCAppSettings sharedSettings];
        settings.presenceEnabled = !settings.isPresenceEnabled;
        switchBtn.on = settings.isPresenceEnabled;
    }
}

#pragma mark - Delegate Handlers -

#pragma mark MFMailComposeViewControllerDelegate

-(void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
