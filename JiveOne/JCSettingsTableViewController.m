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

#import "JCTermsAndConditonsViewController.h"

#import "JCAuthenticationManager.h"

#import <sys/sysctl.h>


#import "PBX.h"

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
    
    /*NSDictionary *localizedDictionary = [[NSBundle mainBundle] localizedInfoDictionary];
    self.appLabel.text = [localizedDictionary objectForKey:@"CFBundleDisplayName"];*/
    
    NSBundle *bundle = [NSBundle mainBundle];
    self.appLabel.text = [bundle objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    self.buildLabel.text = [bundle objectForInfoDictionaryKey:@"CFBundleVersion"];
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
    self.pbxLabel.text          = _authenticationManager.line.pbx.displayName;
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
        
        
        size_t size;
        sysctlbyname("hw.machine", NULL, &size, NULL, 0);
        char *machine = malloc(size);
        sysctlbyname("hw.machine", machine, &size, NULL, 0);
        NSString *platform = [NSString stringWithCString:machine encoding:NSUTF8StringEncoding];
        NSLog(@"iPhone Device%@",[self platformType:platform]);
        free(machine);
        
        
        
        //get device specs
        UIDevice *currentDevice = [UIDevice currentDevice];
        NSString *model         = [self platformType:platform];
        NSString *systemVersion = [currentDevice systemVersion];
        NSString *appVersion    = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
        NSString *country       = [[NSLocale currentLocale] localeIdentifier];
        
        NSString *bodyTemplate = [NSString stringWithFormat:kJCSettingsTableViewControllerFeebackMessage, model, systemVersion, appVersion, country];
        [mailViewController setMessageBody:bodyTemplate isHTML:YES];
        [self presentViewController:mailViewController animated:YES completion:nil];
    }
}

- (NSString *) platformType:(NSString *)platform
{
    if ([platform isEqualToString:@"iPhone1,1"])    return @"iPhone 1G";
    if ([platform isEqualToString:@"iPhone1,2"])    return @"iPhone 3G";
    if ([platform isEqualToString:@"iPhone2,1"])    return @"iPhone 3GS";
    if ([platform isEqualToString:@"iPhone3,1"])    return @"iPhone 4";
    if ([platform isEqualToString:@"iPhone3,3"])    return @"Verizon iPhone 4";
    if ([platform isEqualToString:@"iPhone4,1"])    return @"iPhone 4S";
    if ([platform isEqualToString:@"iPhone5,1"])    return @"iPhone 5 (GSM)";
    if ([platform isEqualToString:@"iPhone5,2"])    return @"iPhone 5 (GSM+CDMA)";
    if ([platform isEqualToString:@"iPhone5,3"])    return @"iPhone 5c (GSM)";
    if ([platform isEqualToString:@"iPhone5,4"])    return @"iPhone 5c (GSM+CDMA)";
    if ([platform isEqualToString:@"iPhone6,1"])    return @"iPhone 5s (GSM)";
    if ([platform isEqualToString:@"iPhone6,2"])    return @"iPhone 5s (GSM+CDMA)";
    if ([platform isEqualToString:@"iPhone7,2"])    return @"iPhone 6";
    if ([platform isEqualToString:@"iPhone7,1"])    return @"iPhone 6 Plus";
    if ([platform isEqualToString:@"iPod1,1"])      return @"iPod Touch 1G";
    if ([platform isEqualToString:@"iPod2,1"])      return @"iPod Touch 2G";
    if ([platform isEqualToString:@"iPod3,1"])      return @"iPod Touch 3G";
    if ([platform isEqualToString:@"iPod4,1"])      return @"iPod Touch 4G";
    if ([platform isEqualToString:@"iPod5,1"])      return @"iPod Touch 5G";
    if ([platform isEqualToString:@"iPad1,1"])      return @"iPad";
    if ([platform isEqualToString:@"iPad2,1"])      return @"iPad 2 (WiFi)";
    if ([platform isEqualToString:@"iPad2,2"])      return @"iPad 2 (GSM)";
    if ([platform isEqualToString:@"iPad2,3"])      return @"iPad 2 (CDMA)";
    if ([platform isEqualToString:@"iPad2,4"])      return @"iPad 2 (WiFi)";
    if ([platform isEqualToString:@"iPad2,5"])      return @"iPad Mini (WiFi)";
    if ([platform isEqualToString:@"iPad2,6"])      return @"iPad Mini (GSM)";
    if ([platform isEqualToString:@"iPad2,7"])      return @"iPad Mini (GSM+CDMA)";
    if ([platform isEqualToString:@"iPad3,1"])      return @"iPad 3 (WiFi)";
    if ([platform isEqualToString:@"iPad3,2"])      return @"iPad 3 (GSM+CDMA)";
    if ([platform isEqualToString:@"iPad3,3"])      return @"iPad 3 (GSM)";
    if ([platform isEqualToString:@"iPad3,4"])      return @"iPad 4 (WiFi)";
    if ([platform isEqualToString:@"iPad3,5"])      return @"iPad 4 (GSM)";
    if ([platform isEqualToString:@"iPad3,6"])      return @"iPad 4 (GSM+CDMA)";
    if ([platform isEqualToString:@"iPad4,1"])      return @"iPad Air (WiFi)";
    if ([platform isEqualToString:@"iPad4,2"])      return @"iPad Air (Cellular)";
    if ([platform isEqualToString:@"iPad4,3"])      return @"iPad Air";
    if ([platform isEqualToString:@"iPad4,4"])      return @"iPad Mini 2G (WiFi)";
    if ([platform isEqualToString:@"iPad4,5"])      return @"iPad Mini 2G (Cellular)";
    if ([platform isEqualToString:@"iPad4,6"])      return @"iPad Mini 2G";
    if ([platform isEqualToString:@"i386"])         return @"Simulator";
    if ([platform isEqualToString:@"x86_64"])       return @"Simulator";
    return platform;
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
