//
//  JCAppMenuViewController.h
//  JiveOne
//
//  Created by Robert Barclay on 4/23/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCAppMenuTableViewController.h"
#import "JCRecentEventsTableViewController.h"

@interface JCAppMenuViewController : UIViewController <JCAppMenuTableViewControllerDelegate>

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *appMenuHeightConstraint;

@property (weak, nonatomic) id<UITableViewDelegate> menuTableViewDelegate;
@property (weak, nonatomic) id<UITableViewDataSource> menuTableViewDataSource;

@property (weak, nonatomic, readonly) JCAppMenuTableViewController *appMenuTableViewController;
@property (weak, nonatomic, readonly) JCRecentEventsTableViewController *recentEventsTableViewController;
@property (weak, nonatomic, readonly) UITableViewController *menuTableViewController;

@end
