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
#import "Line.h"

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

-(void)enableIntercomMicrophoneMuteSwitch:(BOOL)enabled
{
    self.intercomMicrophoneMuteCell.userInteractionEnabled = enabled;
    self.intercomMicrophoneMuteLabel.enabled = enabled;
    self.intercomeMicrophoneMuteSwitch.enabled = enabled;
}

-(NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (section == 0) {
        return [NSString stringWithFormat:[super tableView:self.tableView titleForFooterInSection:0], [JCAuthenticationManager sharedInstance].line.number];
    } else {
        return [super tableView:tableView titleForFooterInSection:section];
    }
}

@end
