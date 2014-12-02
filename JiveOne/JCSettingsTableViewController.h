//
//  JCSettingsTableViewController.h
//  JiveOne
//
//  Created by Robert Barclay on 11/19/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JCSettingsTableViewController : UITableViewController

@property (weak, nonatomic) IBOutlet UILabel *userNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *extensionLabel;
@property (weak, nonatomic) IBOutlet UILabel *pbxLabel;
@property (weak, nonatomic) IBOutlet UILabel *appLabel;
@property (weak, nonatomic) IBOutlet UILabel *buildLabel;

@property (weak, nonatomic) IBOutlet UITableViewCell *logoutCell;

-(IBAction)leaveFeedback:(id)sender;
-(IBAction)logout:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *lineConfigpage;

@end
