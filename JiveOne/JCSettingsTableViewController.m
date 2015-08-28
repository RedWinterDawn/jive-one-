//
//  JCSettingsTableViewController.m
//  JiveOne
//
//  Created by Robert Barclay on 11/19/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

@import MessageUI;

#import "JCSettingsTableViewController.h"
#import <uservoice_iphone_sdk/UserVoice.h>
#import <JCPhoneModule/JCPhoneModule.h>

// Managers
#import "JCUserManager.h"

// Models
#import "JCAppSettings.h"
#import "PBX.h"
#import "DID.h"
#import "User.h"
#import "Line.h"

// Controllers
#import "JCTermsAndConditonsViewController.h"
#import "JCDIDSelectorViewController.h"
#import "UIDevice+JCPhone.h"

NSString *const kJCSettingsTableViewControllerFeebackMessage = @"<strong>Feedback :</strong><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><hr><strong>Device Specs</strong><br>Model: %@ <br> On iOS Version: %@ <br> App Version: %@ <br> Country: %@ <br> UUID : %@  <br> PBX : %@  <br> User : %@  <br> Line : %@ <br> Domain : %@  <br> Carrier : %@ <br> Connection Type : %@ <br> ";

@interface JCSettingsTableViewController () <JCDIDSelectorViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *userNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *appLabel;
@property (weak, nonatomic) IBOutlet UILabel *buildLabel;
@property (weak, nonatomic) IBOutlet UILabel *installationIdentifier;
@property (weak, nonatomic) IBOutlet UILabel *uuid;
@property (weak, nonatomic) IBOutlet UILabel *pbx;

@property (weak, nonatomic) IBOutlet UISwitch *presenceEnabled;
@property (weak, nonatomic) IBOutlet UITableViewCell *presenceCell;

@property (weak, nonatomic) IBOutlet UILabel *smsUserDefaultNumber;
@property (weak, nonatomic) IBOutlet UITableViewCell *defaultDIDCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *blockedNumbersCell;

@property (weak, nonatomic) IBOutlet UITableViewCell *debugCell;

@property (nonatomic, strong) AFNetworkReachabilityManager *networkReachabilityManager;
@property (nonatomic) JCPhoneAudioManager* audioManager;

@end

@implementation JCSettingsTableViewController

-(void)viewDidLoad
{
    [super viewDidLoad];
   
    // Device Info
    UIDevice *device = [UIDevice currentDevice];
    self.installationIdentifier.text = device.installationIdentifier;
    self.hideSectionsWithHiddenRows = TRUE;
    
    // App Info
    NSBundle *bundle = [NSBundle mainBundle];
    self.appLabel.text = [bundle objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    self.buildLabel.text = [NSString stringWithFormat:@"%@ (%@)", [bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"], [bundle objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey]];
    
    #ifndef DEBUG
    if (self.debugCell) {
        [self setCell:self.debugCell hidden:YES];
    }
    #endif
    
    // Authentication Info
    JCUserManager *userManager = self.userManager;
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(updateAccountInfo) name:kJCAuthenticationManagerLineChangedNotification object:userManager];
    [center addObserver:self selector:@selector(updateAccountInfo) name:kJCAuthenticationManagerUserLoadedMinimumDataNotification object:userManager];
    [center addObserver:self selector:@selector(updateAccountInfo) name:kJCAuthenticationManagerUserLoggedOutNotification object:userManager];
    
    [self updateAccountInfo];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updateAccountInfo];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self updateAccountInfo];
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

-(IBAction)togglePresenceEnabled:(id)sender
{
    [self toggleSettingForSender:sender
                          action:^BOOL(JCAppSettings *s) {
                              s.presenceEnabled = !s.isPresenceEnabled;
                              return s.isPresenceEnabled;
                          } completion:NULL];
}

-(IBAction)leaveFeedback:(id)sender
{
    JCUserManager *userManager = self.userManager;
    NSString *email = userManager.user.jiveUserId;
    if ([email rangeOfString:@"@"].location == NSNotFound){
        email =  [email stringByAppendingString:@"@jive.com"];
    }
    
    UVConfig *config = [UVConfig configWithSite:@"jivemobile.uservoice.com"];
    [config identifyUserWithEmail: email name: email guid: email];
    
    config.showForum = NO;
    config.showPostIdea = NO;
    
    NSMutableDictionary *fields = [NSMutableDictionary new];
    
    // Device Info
    UIDevice *currentDevice = [UIDevice currentDevice];
    [fields setValue:[currentDevice platformType] forKey:@"Model"];
    [fields setValue:[currentDevice systemVersion] forKey:@"System Version"];
    [fields setValue:[currentDevice userUniqueIdentiferForUser:userManager.user.jiveUserId] forKey:@"UUID"];
    
    // App Info
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *appVersion = [NSString stringWithFormat:@"%@ (%@)", [bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"], [bundle objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey]];
    [fields setValue:appVersion forKey:@"App Version"];
    
    NSString *country = [[NSLocale currentLocale] localeIdentifier];
    [fields setValue:country forKey:@"Locale"];
    
    NSString *user = userManager.line.pbx.user.jiveUserId;
    [fields setValue:user forKey:@"User"];
    
    NSString *pbx = userManager.line.pbx.displayName;
    [fields setValue:pbx forKey:@"PBX"];
    
    NSString *line = userManager.line.number;
    [fields setValue:line forKey:@"Line"];
    
    NSString *domain = userManager.line.pbx.domain;
    [fields setValue:domain forKey:@"Domain"];
    
    NSString *carrier = [currentDevice defaultCarrier];
    [fields setValue:carrier forKey:@"Carrier"];
    
    NSString *currentConection =  [self networkType];
    [fields setValue:currentConection forKey:@"Network"];
    
    config.customFields = fields;
    
    [UserVoice initialize:config];
    
    [UserVoice presentUserVoiceInterfaceForParentViewController:self];
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

-(AFNetworkReachabilityManager *)networkReachabilityManager
{
    if (!_networkReachabilityManager) {
        _networkReachabilityManager = [AFNetworkReachabilityManager sharedManager];
    }
    return _networkReachabilityManager;
}

-(IBAction)logout:(id)sender
{
    [self.userManager logout];
}

-(void)didUpdateDIDSelectorViewController:(JCDIDSelectorViewController *)viewController
{
    [self updateAccountInfo];
}

#pragma mark - Notification Handlers -

-(void)updateAccountInfo
{
    JCUserManager *userManager = self.userManager;
    UIDevice *device = [UIDevice currentDevice];
    
    self.uuid.text                  = [device userUniqueIdentiferForUser:userManager.user.jiveUserId];
    self.userNameLabel.text         = userManager.user.jiveUserId;
    self.pbx.text                   = userManager.pbx.name;
    
    [self startUpdates];
    
    // Presence
    PBX *pbx = userManager.pbx;
    [self setCell:self.presenceCell hidden:!pbx.isV5];
    self.presenceEnabled.on = self.appSettings.isPresenceEnabled;
    
    self.smsUserDefaultNumber.text = userManager.did.formattedNumber;
    [self setCell:self.defaultDIDCell hidden:!pbx.sendSMSMessages];
    [self setCell:self.blockedNumbersCell hidden:!pbx.sendSMSMessages];
    
    [self endUpdates];
}

@end
