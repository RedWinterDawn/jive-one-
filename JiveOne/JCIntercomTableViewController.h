//
//  JCIntercomTableViewController.h
//  JiveOne
//
//  Created by Robert Barclay on 2/4/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

@import UIKit;

@interface JCIntercomTableViewController : UITableViewController

@property (weak, nonatomic) IBOutlet UISwitch *intercomSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *intercomeMicrophoneMuteSwitch;
@property (weak, nonatomic) IBOutlet UITableViewCell *intercomMicrophoneMuteCell;
@property (weak, nonatomic) IBOutlet UILabel *intercomMicrophoneMuteLabel;

-(IBAction)intercomChanged:(id)sender;
-(IBAction)intercomMicrophoneMuteChanged:(id)sender;

@end
