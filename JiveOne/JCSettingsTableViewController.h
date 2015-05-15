//
//  JCSettingsTableViewController.h
//  JiveOne
//
//  Created by Robert Barclay on 11/19/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <StaticDataTableViewController/StaticDataTableViewController.h>

@interface JCSettingsTableViewController : StaticDataTableViewController

@property (weak, nonatomic) IBOutlet UILabel *userNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *extensionLabel;
@property (weak, nonatomic) IBOutlet UILabel *appLabel;
@property (weak, nonatomic) IBOutlet UILabel *buildLabel;
@property (weak, nonatomic) IBOutlet UILabel *installationIdentifier;
@property (weak, nonatomic) IBOutlet UILabel *uuid;
@property (weak, nonatomic) IBOutlet UILabel *smsUserDefaultNumber;
@property (weak, nonatomic) IBOutlet UITableViewCell *defaultDIDCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *blockedNumbersCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *enablePreasenceCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *debugCell;
@property (weak, nonatomic) IBOutlet UISwitch *wifiOnly;
@property (weak, nonatomic) IBOutlet UISwitch *presenceEnabled;

-(IBAction)leaveFeedback:(id)sender;
-(IBAction)logout:(id)sender;
-(IBAction)toggleWifiOnly:(id)sender;
-(IBAction)togglePresenceEnabled:(id)sender;
-(IBAction)showDebug:(id)sender;

@end
