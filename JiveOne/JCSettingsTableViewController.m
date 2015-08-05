//
//  JCSettingsTableViewController.m
//  JiveOne
//
//  Created by Robert Barclay on 11/19/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

@import MessageUI;


#import "JCSettingsTableViewController.h"
#import <UserVoice.h>

// Managers
#import "JCAuthenticationManager.h"

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
//        [self cell:self.debugCell setHidden:YES];
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
    JCAuthenticationManager *authenticationManager = self.authenticationManager;
    NSString *email = authenticationManager.user.jiveUserId;
    if ([email rangeOfString:@"@"].location == NSNotFound){
        email =  [email stringByAppendingString:@"@jive.com"];
    }
    
    UVConfig *config = [UVConfig configWithSite:@"jivemobile.uservoice.com"];
    [config identifyUserWithEmail: email name: email guid: email];
    
    config.showForum = NO;
    config.showPostIdea = NO;
    [UserVoice initialize:config];
    
    [UserVoice presentUserVoiceInterfaceForParentViewController:self];
}

-(IBAction)logout:(id)sender
{
    [self.authenticationManager logout];
}

-(void)didUpdateDIDSelectorViewController:(JCDIDSelectorViewController *)viewController
{
    [self updateAccountInfo];
}

#pragma mark - Notification Handlers -

-(void)updateAccountInfo
{
    JCAuthenticationManager *authenticationManager = self.authenticationManager;
    UIDevice *device = [UIDevice currentDevice];
    
    self.uuid.text                  = [device userUniqueIdentiferForUser:authenticationManager.jiveUserId];
    self.userNameLabel.text         = authenticationManager.user.jiveUserId;
    self.pbx.text                   = authenticationManager.pbx.name;
    
    [self startUpdates];
    
    // Presence
    PBX *pbx = authenticationManager.pbx;
    [self setCell:self.presenceCell hidden:!pbx.isV5];
    self.presenceEnabled.on = self.appSettings.isPresenceEnabled;
    
    self.smsUserDefaultNumber.text = authenticationManager.did.formattedNumber;
    [self setCell:self.defaultDIDCell hidden:!pbx.sendSMSMessages];
    [self setCell:self.blockedNumbersCell hidden:!pbx.sendSMSMessages];
    
    [self endUpdates];
}

@end
