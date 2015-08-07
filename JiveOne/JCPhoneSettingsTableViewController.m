//
//  JCIntercomTableViewController.m
//  JiveOne
//
//  Created by Robert Barclay on 2/4/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCPhoneSettingsTableViewController.h"
#import "JCAppSettings.h"
#import "JCAuthenticationManager.h"
#import "JCPhoneManager.h"
#import "Line.h"
#import "PBX.h"

@interface JCPhoneSettingsTableViewController ()

@property (weak, nonatomic) IBOutlet UISwitch *intercomSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *microphoneMuteSwitch;

@property (weak, nonatomic) IBOutlet UISwitch *doNotDisturbSW;
@property (weak, nonatomic) IBOutlet UISwitch *wifiOnly;

@property (weak, nonatomic) IBOutlet UISwitch *sipDisabled;

@property (weak, nonatomic) IBOutlet UITableViewCell *microphoneMuteCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *extensionCell;

@property (weak, nonatomic) IBOutlet UILabel *microphoneMuteLabel;

@property (strong, nonatomic) IBOutletCollection(UITableViewCell) NSArray *enabledPhoneSettings;

@end

@implementation JCPhoneSettingsTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self updatePhoneInfo];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updatePhoneInfo];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self updatePhoneInfo];
}

#pragma mark - IBActions -

- (IBAction)toggleEnablePhone:(id)sender
{
    [self toggleSettingForSender:sender
                          action:^BOOL(JCAppSettings *s) {
                              s.phoneEnabled = !s.isPhoneEnabled;
                              return s.isPhoneEnabled;
                          }
                      completion:^(BOOL value, JCAppSettings *settings) {
                          [self updatePhoneInfo];
                          if (value){
                              [self.phoneManager connectWithProvisioningProfile:self.authenticationManager.line];
                          } else{
                              [self.phoneManager disconnect];
                          }
                      }];
}

-(IBAction)intercomChanged:(id)sender
{
    [self toggleSettingForSender:sender
                          action:^BOOL(JCAppSettings *s) {
                              s.intercomEnabled = !s.isIntercomEnabled;
                              return s.isIntercomEnabled;
                          }
                      completion:^(BOOL value, JCAppSettings *s) {
                          if (s.isIntercomEnabled == FALSE) {
                              s.intercomMicrophoneMuteEnabled = TRUE;
                          }
                          self.microphoneMuteSwitch.on = s.isIntercomMicrophoneMuteEnabled;
                          [self setCell:self.microphoneMuteCell enabled:s.isIntercomEnabled];
                      }];
}

-(IBAction)intercomMicrophoneMuteChanged:(id)sender
{
    [self toggleSettingForSender:sender
                          action:^BOOL(JCAppSettings *s) {
                              s.intercomMicrophoneMuteEnabled = !s.isIntercomMicrophoneMuteEnabled;
                              return s.isIntercomMicrophoneMuteEnabled;
                          }
                      completion:NULL];
}

-(IBAction)toggleWifiOnly:(id)sender
{
    [self toggleSettingForSender:sender
                          action:^BOOL(JCAppSettings *s) {
                              s.wifiOnly = !s.isWifiOnly;
                              return s.isWifiOnly;
                          }
                      completion:^(BOOL value, JCAppSettings *s) {
                          [self.phoneManager connectWithProvisioningProfile:self.authenticationManager.line];
                      }];
}



- (IBAction)toggleDoNotDisturb:(id)sender {
    
    [self toggleSettingForSender:sender
                          action:^BOOL(JCAppSettings *s) {
                              s.doNotDisturbEnabled = !s.isDoNotDisturbEnabled;
                              return s.isDoNotDisturbEnabled;
                          }
                      completion:NULL];
}

#pragma mark - Private -

-(void)updatePhoneInfo
{
    Line *line = self.authenticationManager.line;
    self.extensionCell.detailTextLabel.text = line.number;
    
    JCAppSettings *settings = self.appSettings;
    self.intercomSwitch.on  = settings.isIntercomEnabled;
    self.wifiOnly.on        = settings.wifiOnly;
    self.sipDisabled.on     = settings.phoneEnabled;
    self.doNotDisturbSW.on  = settings.doNotDisturbEnabled;
    self.microphoneMuteSwitch.on = settings.isIntercomMicrophoneMuteEnabled;
    
    [self startUpdates];
    
    [self setCells:self.enabledPhoneSettings enabled:settings.isPhoneEnabled];
    [self setCell:self.microphoneMuteCell enabled:settings.isIntercomEnabled];
    
    [self endUpdates];
}

-(void)setCell:(UITableViewCell *)cell enabled:(BOOL)enabled
{
    if (cell == _microphoneMuteCell) {
        _microphoneMuteCell.userInteractionEnabled = enabled;
        _microphoneMuteLabel.enabled = enabled;
        _microphoneMuteSwitch.enabled = enabled;
    } else {
        [super setCell:cell enabled:enabled];
    }
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
