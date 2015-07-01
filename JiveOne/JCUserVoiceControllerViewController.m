//
//  JCUserVoiceControllerViewController.m
//  JiveOne
//
//  Created by P Leonard on 6/2/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCUserVoiceControllerViewController.h"
#import "JCSettingsTableViewController.h"
#import "UserVoice.h"

#import "JCAuthenticationManager.h"
#import "JCPhoneManager.h"

// Models
#import "JCAppSettings.h"
#import "PBX.h"
#import "DID.h"
#import "User.h"
#import "Line.h"




@implementation UVViewController



- (void)viewDidLoad {
    [super viewDidLoad];
    [self configureUser];
    
    UVConfig *config = [UVConfig configWithSite:@"jivemobile.uservoice.com"];
    //    UVConfig *config = [UVConfig configWithSite:@"demo.uservoice.com"];
    JCAuthenticationManager *authenticationManager = self.authenticationManager;
    [config identifyUserWithEmail:authenticationManager.line.pbx.user.jiveUserId name:authenticationManager.line.pbx.user.jiveUserId guid:authenticationManager.line.pbx.user.jiveUserId];

//    [config identifyUserWithEmail: _user name: _line, guid: _domain);

    [UserVoice initialize:config];
}
     
-(void)configureUser{
    JCAuthenticationManager *authenticationManager = self.authenticationManager;
    
    NSBundle *bundle            = [NSBundle mainBundle];
    UIDevice *currentDevice     = [UIDevice currentDevice];
//    NSString *model             = [currentDevice platformType];
//    NSString *systemVersion     = [currentDevice systemVersion];
//    NSString *appVersion        = [NSString stringWithFormat:@"%@ (%@)", [bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"], [bundle objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey]];
//    NSString *country           = [[NSLocale currentLocale] localeIdentifier];

    _uuid = [currentDevice userUniqueIdentiferForUser:authenticationManager.jiveUserId];
    _pbx              = authenticationManager.line.pbx.displayName;
    _user              = authenticationManager.line.pbx.user.jiveUserId;
    _line              = authenticationManager.line.number;
    _domain        = authenticationManager.line.pbx.domain;
    _carrier          = [currentDevice defaultCarrier];

    

}
     
     
- (IBAction)launchUserVoice:(id)sender {
    [UserVoice presentUserVoiceInterfaceForParentViewController:self];
}

- (IBAction)launchForum:(id)sender {
    [UserVoice presentUserVoiceForumForParentViewController:self];
}

- (IBAction)launchIdeaForm:(id)sender {
    [UserVoice presentUserVoiceNewIdeaFormForParentViewController:self];
}

- (IBAction)launchTicketForm:(id)sender {
    [UserVoice presentUserVoiceContactUsFormForParentViewController:self];
}


@end
