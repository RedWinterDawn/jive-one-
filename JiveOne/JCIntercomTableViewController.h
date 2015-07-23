//
//  JCIntercomTableViewController.h
//  JiveOne
//
//  Created by Robert Barclay on 2/4/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import <StaticDataTableViewController/StaticDataTableViewController.h>
@import UIKit;

@interface JCIntercomTableViewController : StaticDataTableViewController

@property (weak, nonatomic) IBOutlet UISwitch *intercomSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *intercomeMicrophoneMuteSwitch;
@property (weak, nonatomic) IBOutlet UITableViewCell *intercomMicrophoneMuteCell;
@property (weak, nonatomic) IBOutlet UILabel *intercomMicrophoneMuteLabel;
@property (weak, nonatomic) IBOutlet UISwitch *doNotDisturbSW;
@property (weak, nonatomic) IBOutlet UISwitch *wifiOnly;
@property (weak, nonatomic) IBOutlet UISwitch *presenceEnabled;
@property (weak, nonatomic) IBOutlet UISwitch *sipDisabled;
@property (weak, nonatomic) IBOutlet UITableViewCell *enablePreasenceCell;



-(IBAction)intercomChanged:(id)sender;
-(IBAction)intercomMicrophoneMuteChanged:(id)sender;
-(IBAction)toggleWifiOnly:(id)sender;
-(IBAction)togglePresenceEnabled:(id)sender;
- (IBAction)toggleDoNotDisturb:(id)sender;

@end
