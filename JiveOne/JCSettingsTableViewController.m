//
//  JCSettingsTableViewController.m
//  JiveOne
//
//  Created by Robert Barclay on 11/19/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

@import MessageUI;
@import AVFoundation;
@import MediaPlayer;

#import "JCSettingsTableViewController.h"

// Managers
#import "JCAuthenticationManager.h"
#import "JCPhoneManager.h"
#import "JCPhoneAudioManager.h"

// Models
#import "JCAppSettings.h"
#import "PBX.h"
#import "DID.h"
#import "User.h"
#import "Line.h"

// Controllers
#import "JCTermsAndConditonsViewController.h"
#import "JCDIDSelectorViewController.h"

NSString *const kJCSettingsTableViewControllerFeebackMessage = @"<strong>Feedback :</strong><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><hr><strong>Device Specs</strong><br>Model: %@ <br> On iOS Version: %@ <br> App Version: %@ <br> Country: %@ <br> UUID : %@  <br> PBX : %@  <br> User : %@  <br> Line : %@ <br> Domain : %@  <br> Carrier : %@ <br> Connection Type : %@ <br> ";

@interface JCSettingsTableViewController () <MFMailComposeViewControllerDelegate, JCDIDSelectorViewControllerDelegate>

@property (nonatomic, strong) AFNetworkReachabilityManager *networkReachabilityManager;
@property (nonatomic) JCPhoneAudioManager* audioManager;

@end

@implementation JCSettingsTableViewController

-(void)viewDidLoad
{
    [super viewDidLoad];
   
   
    _audioManager = [JCPhoneAudioManager new];
    [_audioManager setSessionActive];
    MPVolumeView *volumeView = [MPVolumeView new];
    self.routeIconBackground.hidden = !volumeView.showsRouteButton;
    // Device Info
    UIDevice *device = [UIDevice currentDevice];
    self.installationIdentifier.text = device.installationIdentifier;
    self.hideSectionsWithHiddenRows = TRUE;
    
    // App Info
    NSBundle *bundle = [NSBundle mainBundle];
    self.appLabel.text = [bundle objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    self.buildLabel.text = [NSString stringWithFormat:@"%@ (%@)", [bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"], [bundle objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey]];
    
    // Settings Info
    JCAppSettings *settings = self.appSettings;
    self.wifiOnly.on = settings.wifiOnly;
    self.presenceEnabled.on = settings.presenceEnabled;
    self.sipDisabled.on = settings.sipDisabled;
    _volumeslidder.value = settings.volumeLevel;

    
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

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self updateAccountInfo];
}

-(void)awakeFromNib
{
    [super awakeFromNib];
    
    #ifndef DEBUG
    self.navigationItem.rightBarButtonItem = nil;
    #endif
}

-(void)viewWillDisappear:(BOOL)animated{
    if (_audioManager)
    {
        [_audioManager stop];
    }
    
}
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UIViewController *controller = segue.destinationViewController;
    if ([controller isKindOfClass:[UINavigationController class]]) {
        controller = ((UINavigationController *)controller).topViewController;
    }
    
    if ([controller isKindOfClass:[JCTermsAndConditonsViewController class]]) {
        controller.navigationItem.leftBarButtonItem = nil;
    } else if ([controller isKindOfClass:[JCDIDSelectorViewController class]]) {
        ((JCDIDSelectorViewController *)controller).delegate = self;
    }
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - IBActions -

- (IBAction)sliderValue:(id)sender {
    self.appSettings.volumeLevel = _volumeslidder.value;
    [_audioManager playIncomingCallToneDemo];  //Plays a snippit of the ringer so the user know how load it is going ot be.
}

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
- (IBAction)toggleDisableSip:(id)sender {
    if([sender isKindOfClass:[UISwitch class]]){
        UISwitch *switchBtn = (UISwitch *)sender;
        JCAppSettings *settings = self.appSettings;
        settings.sipDisabled = !settings.sipDisabled;
        switchBtn.on = settings.isSipDisabled;
        if (settings.isSipDisabled){
            [self.phoneManager disconnect];
        } else{
            [self.phoneManager connectToLine:self.authenticationManager.line];
        }
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
    self.smsUserDefaultNumber.text  = authenticationManager.did.formattedNumber;
    
    PBX *pbx = authenticationManager.pbx;
    [self cell:self.enablePreasenceCell setHidden:!pbx.isV5];
    [self cell:self.defaultDIDCell setHidden:!pbx.sendSMSMessages];
    [self cell:self.blockedNumbersCell setHidden:!pbx.sendSMSMessages];
    
    [self reloadDataAnimated:NO];
}

#pragma mark - Delegate Handlers -

#pragma mark MFMailComposeViewControllerDelegate

-(void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)didUpdateDIDSelectorViewController:(JCDIDSelectorViewController *)viewController
{
    [self updateAccountInfo];
}

@end
