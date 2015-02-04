//
//  JCIntercomTableViewController.m
//  JiveOne
//
//  Created by Robert Barclay on 2/4/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCIntercomTableViewController.h"
#import "JCAppSettings.h"

@implementation JCIntercomTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    JCAppSettings *settings = [JCAppSettings sharedSettings];
    self.intercomSwitch.on = settings.isIntercomEnabled;
    [self enableIntercomMicrophoneMuteSwitch:settings.isIntercomEnabled];
    self.intercomeMicrophoneMuteSwitch.on = settings.isIntercomMicrophoneMuteEnabled;
}

-(IBAction)intercomChanged:(id)sender
{
    if ([sender isKindOfClass:[UISwitch class]]) {
        UISwitch *switchBtn = (UISwitch *)sender;
        JCAppSettings *settings = [JCAppSettings sharedSettings];
        settings.intercomEnabled = !settings.isIntercomEnabled;
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

-(void)enableIntercomMicrophoneMuteSwitch:(BOOL)enabled
{
    self.intercomMicrophoneMuteCell.userInteractionEnabled = enabled;
    self.intercomMicrophoneMuteLabel.enabled = enabled;
    self.intercomeMicrophoneMuteSwitch.enabled = enabled;
}

@end
