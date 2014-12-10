//
//  JCDebugTableViewController.h
//  JiveOne
//
//  Created by Robert Barclay on 12/10/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JCDebugTableViewController : UITableViewController

@property (weak, nonatomic) IBOutlet UILabel *users;
@property (weak, nonatomic) IBOutlet UILabel *pbxs;
@property (weak, nonatomic) IBOutlet UILabel *lines;
@property (weak, nonatomic) IBOutlet UILabel *lineConfigurations;
@property (weak, nonatomic) IBOutlet UILabel *events;
@property (weak, nonatomic) IBOutlet UILabel *missed;
@property (weak, nonatomic) IBOutlet UILabel *voicemails;

@end
