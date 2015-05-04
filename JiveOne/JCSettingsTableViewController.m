//
//  JCSettingsTableViewController.m
//  JiveOne
//
//  Created by Robert Barclay on 11/19/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

@import MessageUI;

#import "JCSettingsTableViewController.h"

// Managers
#import "JCAuthenticationManager.h"
#import "JCPhoneManager.h"

// Models
#import "JCAppSettings.h"
#import "PBX.h"
#import "DID.h"
#import "User.h"
#import "Line.h"

// Controllers
#import "JCTermsAndConditonsViewController.h"

NSString *const kJCSettingsTableViewControllerFeebackMessage = @"<strong>Feedback :</strong><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><hr><strong>Device Specs</strong><br>Model: %@ <br> On iOS Version: %@ <br> App Version: %@ <br> Country: %@ <br> UUID : %@  <br> PBX : %@  <br> User : %@  <br> Line : %@ <br> Domain : %@  <br> Carrier : %@ <br> Connection Type : %@ <br> ";

@interface JCSettingsTableViewController () <MFMailComposeViewControllerDelegate>

@property (nonatomic, strong) AFNetworkReachabilityManager *networkReachabilityManager;

@end

@implementation JCSettingsTableViewController

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    // Device Info
    UIDevice *device = [UIDevice currentDevice];
    self.installationIdentifier.text = device.installationIdentifier;
    
    // App Info
    NSBundle *bundle = [NSBundle mainBundle];
    self.appLabel.text = [bundle objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    self.buildLabel.text = [NSString stringWithFormat:@"%@ (%@)", [bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"], [bundle objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey]];
    
    // Settings Info
    JCAppSettings *settings = self.appSettings;
    self.wifiOnly.on = settings.wifiOnly;
    self.presenceEnabled.on = settings.presenceEnabled;
    
    #ifndef DEBUG
    if (self.debugCell) {
        [self cell:self.debugCell setHidden:YES];
    }
    #endif
    
    // Authentication Info
    JCAuthenticationManager *authenticationManager = self.authenticationManager;
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(updateAccountInfo) name:kJCAuthenticationManagerLineChangedNotification object:authenticationManager];
    [center addObserver:self selector:@selector(updateAccountInfo) name:kJCAuthenticationManagerUserLoadedMinimumDataNotification object:authenticationManager];
    [center addObserver:self selector:@selector(updateAccountInfo) name:kJCAuthenticationManagerUserLoggedOutNotification object:authenticationManager];
    
    [self updateAccountInfo];
}

-(void)awakeFromNib
{
    [super awakeFromNib];
    
    #ifndef DEBUG
    self.navigationItem.rightBarButtonItem = nil;
    #endif
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UIViewController *controller = segue.destinationViewController;
    if ([controller isKindOfClass:[JCTermsAndConditonsViewController class]]) {
        controller.navigationItem.leftBarButtonItem = nil;
    }
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
        NSString *domain        = authenticationManager.line.pbx.domain;
        NSString *carrier          = [currentDevice defaultCarrier];
        
        NSString *currentConection =  [self networkType];
        
        NSString *bodyTemplate = [NSString stringWithFormat:kJCSettingsTableViewControllerFeebackMessage, model, systemVersion, appVersion, country, uuid, pbx, user, line, domain, carrier, currentConection];
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

-(IBAction)togglePresenceEnabled:(id)sender
{
    if ([sender isKindOfClass:[UISwitch class]]) {
        UISwitch *switchBtn = (UISwitch *)sender;
        self.appSettings.presenceEnabled = !self.appSettings.isPresenceEnabled;
        switchBtn.on = self.appSettings.isPresenceEnabled;
    }
}

-(IBAction)showDebug:(id)sender
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Debug" bundle:[NSBundle mainBundle]];
    UIViewController *rootViewController = [storyboard instantiateInitialViewController];
    [self.navigationController pushViewController:rootViewController animated:YES];
}

#pragma mark - Getters -

-(AFNetworkReachabilityManager *)networkReachabilityManager
{
    if (!_networkReachabilityManager) {
        _networkReachabilityManager = [AFNetworkReachabilityManager sharedManager];
    }
    return _networkReachabilityManager;
}

-(NSString *)networkType
{
    AFNetworkReachabilityStatus status = self.networkReachabilityManager.networkReachabilityStatus;
    switch (status) {
        case -1:
            return (@"Unreachable");
            break;
        case 1:
            return (@"WAN");
            break;
        case 2:
            return (@"Wifi");
            break;
        default:
            return (@"Network Unobtainable");
            break;
    }
}

#pragma mark - Notification Handlers -

-(void)updateAccountInfo
{
    JCAuthenticationManager *authenticationManager = self.authenticationManager;
    UIDevice *device = [UIDevice currentDevice];
    
    self.uuid.text                  = [device userUniqueIdentiferForUser:authenticationManager.jiveUserId];
    self.userNameLabel.text         = authenticationManager.line.pbx.user.jiveUserId;
    self.extensionLabel.text        = authenticationManager.line.number;
    self.smsUserDefaultNumber.text  = authenticationManager.did.number;
    
    [self cell:self.enablePreasenceCell setHidden:!authenticationManager.line.pbx.isV5];
    [self cell:self.defaultDIDCell setHidden:!authenticationManager.pbx.sendSMSMessages];
    
    [self reloadDataAnimated:NO];
}

#pragma mark - Delegate Handlers -

#pragma mark MFMailComposeViewControllerDelegate

-(void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
