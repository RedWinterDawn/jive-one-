//
//  JCIntercomTableViewController.h
//  JiveOne
//
//  Created by Robert Barclay on 2/4/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCStaticTableViewController.h"

@interface JCPhoneSettingsTableViewController : JCStaticTableViewController

@property (weak, nonatomic) IBOutlet UISwitch *intercomSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *microphoneMuteSwitch;

@property (weak, nonatomic) IBOutlet UISwitch *doNotDisturbSW;
@property (weak, nonatomic) IBOutlet UISwitch *wifiOnly;

@property (weak, nonatomic) IBOutlet UISwitch *sipDisabled;

@property (weak, nonatomic) IBOutlet UITableViewCell *enablePreasenceCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *microphoneMuteCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *extensionCell;

@property (weak, nonatomic) IBOutlet UILabel *microphoneMuteLabel;

@property (strong, nonatomic) IBOutletCollection(UITableViewCell) NSArray *enabledPhoneSettings;

-(IBAction)intercomChanged:(id)sender;
-(IBAction)intercomMicrophoneMuteChanged:(id)sender;
-(IBAction)toggleWifiOnly:(id)sender;
-(IBAction)togglePresenceEnabled:(id)sender;
-(IBAction)toggleDoNotDisturb:(id)sender;

@end
