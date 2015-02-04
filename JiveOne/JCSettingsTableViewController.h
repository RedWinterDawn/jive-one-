//
//  JCSettingsTableViewController.h
//  JiveOne
//
//  Created by Robert Barclay on 11/19/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

@import UIKit;

@interface JCSettingsTableViewController : UITableViewController

@property (weak, nonatomic) IBOutlet UILabel *userNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *extensionLabel;
@property (weak, nonatomic) IBOutlet UILabel *appLabel;
@property (weak, nonatomic) IBOutlet UILabel *buildLabel;
@property (weak, nonatomic) IBOutlet UISwitch *wifiOnly;
@property (weak, nonatomic) IBOutlet UISwitch *presenceEnabled;
@property (weak, nonatomic) IBOutlet UITableViewCell *enablePreasenceCell;

-(IBAction)leaveFeedback:(id)sender;
-(IBAction)logout:(id)sender;
-(IBAction)toggleWifiOnly:(id)sender;
-(IBAction)togglePresenceEnabled:(id)sender;

@end
