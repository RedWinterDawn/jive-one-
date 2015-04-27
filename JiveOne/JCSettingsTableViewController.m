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
#import "DID.h"
#import "User.h"
#import "Line.h"

NSString *const kJCSettingsTableViewControllerFeebackMessage = @"<strong>Please describe any issues you are experiencing :</strong><br><br><br><br><br><br><br><br><br><br><br><br><br><hr><strong>Device Specs</strong><br>Model: %@ <br> On iOS Version: %@ <br> App Version: %@ <br> Country: %@ <br> UUID : %@  <br> PBX : %@  <br> User : %@  <br> Line : %@  <br> ";

@interface JCSettingsTableViewController () <MFMailComposeViewControllerDelegate>

@end

@implementation JCSettingsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSBundle *bundle = [NSBundle mainBundle];
    self.appLabel.text = [bundle objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    self.buildLabel.text = [NSString stringWithFormat:@"%@ (%@)", [bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"], [bundle objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey]];
    
    UIDevice *device = [UIDevice currentDevice];
    self.installationIdentifier.text = device.installationIdentifier;
    self.uuid.text = [device userUniqueIdentiferForUser:self.authenticationManager.jiveUserId];
    
    JCAppSettings *settings = self.appSettings;
    self.wifiOnly.on = settings.wifiOnly;
    self.presenceEnabled.on = settings.presenceEnabled;
    [self cell:self.enablePreasenceCell setHidden:!self.authenticationManager.line.pbx.isV5];
    [self cell:self.defaultDIDCell setHidden:!self.authenticationManager.pbx.smsEnabled];
    
    #ifndef DEBUG
    if (self.debugCell) {
        [self cell:self.debugCell setHidden:YES];
    }
    #endif
    
    [self reloadDataAnimated:NO];
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
   // [self.view setNeedsLayout];
    
     JCAuthenticationManager *authenticationManager = self.authenticationManager;
    [self cell:self.enablePreasenceCell setHidden:!authenticationManager.line.pbx.isV5];
    BOOL sendSmsMessages = authenticationManager.pbx.sendSMSMessages;
    [self cell:self.defaultDIDCell setHidden:!sendSmsMessages];

    [self reloadDataAnimated:NO];
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    JCAuthenticationManager *authenticationManager = self.authenticationManager;
    self.userNameLabel.text     = authenticationManager.line.pbx.user.jiveUserId;
    self.extensionLabel.text    = authenticationManager.line.number;
    self.smsUserDefaultNumber.text = authenticationManager.did.number;
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
        JCAuthenticationManager *authenticationManager = self.authenticationManager;
        NSBundle *bundle            = [NSBundle mainBundle];
        UIDevice *currentDevice     = [UIDevice currentDevice];
        NSString *model             = [currentDevice platformType];
        NSString *systemVersion     = [currentDevice systemVersion];
        NSString *appVersion        = [NSString stringWithFormat:@"%@ (%@)", [bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"], [bundle objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey]];
        NSString *country           = [[NSLocale currentLocale] localeIdentifier];
        NSString *uuid              = [currentDevice userUniqueIdentiferForUser:authenticationManager.jiveUserId];
        NSString * pbx              = authenticationManager.line.pbx.displayName;
        NSString *user              = authenticationManager.line.pbx.user.jiveUserId;
        NSString *line              = authenticationManager.line.number;
        
        NSString *bodyTemplate = [NSString stringWithFormat:kJCSettingsTableViewControllerFeebackMessage, model, systemVersion, appVersion, country, uuid, pbx, user, line];
        [mailViewController setMessageBody:bodyTemplate isHTML:YES]; 
        [self presentViewController:mailViewController animated:YES completion:nil];
    }
}

-(IBAction)logout:(id)sender
{
    [self.authenticationManager logout];
}

-(IBAction)toggleWifiOnly:(id)sender
{
    if ([sender isKindOfClass:[UISwitch class]]) {
        UISwitch *switchBtn = (UISwitch *)sender;
        JCAppSettings *settings = self.appSettings;
        settings.wifiOnly = !settings.isWifiOnly;
        switchBtn.on = settings.isWifiOnly;
        [self.phoneManager connectToLine:self.authenticationManager.line];
    }
}

- (IBAction)togglePresenceEnabled:(id)sender {
    if ([sender isKindOfClass:[UISwitch class]]) {
        UISwitch *switchBtn = (UISwitch *)sender;
        self.appSettings.presenceEnabled = !self.appSettings.isPresenceEnabled;
        switchBtn.on = self.appSettings.isPresenceEnabled;
    }
}

-(IBAction)showDebug:(id)sender{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Debug" bundle:[NSBundle mainBundle]];
    UIViewController *rootViewController = [storyboard instantiateInitialViewController];
    [self.navigationController pushViewController:rootViewController animated:YES];
}

#pragma mark - Delegate Handlers -

#pragma mark MFMailComposeViewControllerDelegate

-(void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
