//
//  JCAppMenuViewController.h
//  JiveOne
//
//  Created by Robert Barclay on 4/21/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import <StaticDataTableViewController/StaticDataTableViewController.h>

@protocol JCAppMenuTableViewControllerDelegate;

@interface JCAppMenuTableViewController : StaticDataTableViewController

@property (weak, nonatomic) id<JCAppMenuTableViewControllerDelegate> delegate;

@property (weak, nonatomic) IBOutlet UITableViewCell *phoneCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *messageCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *contactsCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *settingsViewCell;

@end

@protocol JCAppMenuTableViewControllerDelegate <NSObject>

-(void)appMenuTableViewController:(JCAppMenuTableViewController *)controller willChangeToSize:(CGSize)size;

@end