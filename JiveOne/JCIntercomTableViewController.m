//
//  JCIntercomTableViewController.m
//  JiveOne
//
//  Created by Robert Barclay on 2/4/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCIntercomTableViewController.h"
#import "JCAppSettings.h"
#import "JCAuthenticationManager.h"
#import "JCPhoneManager.h"
#import "Line.h"
#import "PBX.h"

@implementation JCIntercomTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    JCAppSettings *settings = [JCAppSettings sharedSettings];
    self.intercomSwitch.on = settings.isIntercomEnabled;
    [self enableIntercomMicrophoneMuteSwitch:settings.isIntercomEnabled];
    self.intercomeMicrophoneMuteSwitch.on = settings.isIntercomMicrophoneMuteEnabled;
    self.wifiOnly.on = settings.wifiOnly;
    self.presenceEnabled.on = settings.presenceEnabled;
    self.sipDisabled.on = settings.sipDisabled;
    self.doNotDisturbSW.on = settings.doNotDisturbEnabled;
     JCAuthenticationManager *authenticationManager = self.authenticationManager;
    PBX *pbx = authenticationManager.pbx;
    [self cell:self.enablePreasenceCell setHidden:!pbx.isV5];
    
}

-(IBAction)intercomChanged:(id)sender
{
    if ([sender isKindOfClass:[UISwitch class]]) {
        UISwitch *switchBtn = (UISwitch *)sender;
        JCAppSettings *settings = [JCAppSettings sharedSettings];
        settings.intercomEnabled = !settings.isIntercomEnabled;
        if (settings.isIntercomEnabled == FALSE) {
           settings.intercomMicrophoneMuteEnabled = TRUE;
            self.intercomeMicrophoneMuteSwitch.on = settings.isIntercomMicrophoneMuteEnabled;
        }
        [self enableIntercomMicrophoneMuteSwitch:settings.isIntercomEnabled];
        switchBtn.on = settings.isIntercomEnabled;
    }
}

-(IBAction)intercomMicrophoneMuteChanged:(id)sender
{
    if ([sender isKindOfClass:[UISwitch class]]) {
        UISwitch *switchBtn = (UISwitch *)sender;
        JCAppSettings *settings = [JCAppSettings sharedSettings];
        settings.intercomMicrophoneMuteEnabled = !settings.isIntercomMicrophoneMuteEnabled;
        switchBtn.on = settings.isIntercomMicrophoneMuteEnabled;
    }
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

- (IBAction)toggleDoNotDisturb:(id)sender {
    if ([sender isKindOfClass:[UISwitch class]]){
        UISwitch *switchBtn = (UISwitch *)sender;
        JCAppSettings *settings = self.appSettings;
        settings.doNotDisturbEnabled = !settings.doNotDisturbEnabled;
        switchBtn.on = settings.isDoNotDisturbEnabled;
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

-(void)enableIntercomMicrophoneMuteSwitch:(BOOL)enabled
{
    self.intercomMicrophoneMuteCell.userInteractionEnabled = enabled;
    self.intercomMicrophoneMuteLabel.enabled = enabled;
    self.intercomeMicrophoneMuteSwitch.enabled = enabled;
}

-(NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (section == 0) {
        return [NSString stringWithFormat:[super tableView:self.tableView titleForFooterInSection:0], self.authenticationManager.line.number];
    } else {
        return [super tableView:tableView titleForFooterInSection:section];
    }
}

@end
