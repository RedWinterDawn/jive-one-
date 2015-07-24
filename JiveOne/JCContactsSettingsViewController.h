//
//  JCContactsSettingsViewController.h
//  JiveOne
//
//  Created by Robert Barclay on 7/23/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCStaticTableViewController.h"

@interface JCContactsSettingsViewController : JCStaticTableViewController

@property (weak, nonatomic) IBOutlet UISwitch *presenceEnabled;
@property (weak, nonatomic) IBOutlet UITableViewCell *presenceCell;

@end
