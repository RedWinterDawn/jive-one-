//
//  JCContactsSettingsViewController.m
//  JiveOne
//
//  Created by Robert Barclay on 7/23/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCContactsSettingsViewController.h"
#import "JCAppSettings.h"
#import "PBX.h"

@interface JCContactsSettingsViewController ()

@end

@implementation JCContactsSettingsViewController

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    PBX *pbx = self.authenticationManager.pbx;
    [self setCell:self.presenceCell hidden:!pbx.isV5];
    self.presenceEnabled.on = self.appSettings.presenceEnabled;
}

-(IBAction)togglePresenceEnabled:(id)sender
{
    [self toggleSettingForSender:sender
                          action:^BOOL(JCAppSettings *s) {
                              s.presenceEnabled = !s.isPresenceEnabled;
                              return s.isPresenceEnabled;
                          } completion:NULL];
}

@end
