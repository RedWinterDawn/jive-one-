//
//  JCAppMenuViewController.m
//  JiveOne
//
//  Created by Robert Barclay on 4/23/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCAppMenuViewController.h"

@implementation JCAppMenuViewController

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UIViewController *viewController = segue.destinationViewController;
    if ([viewController isKindOfClass:[UINavigationController class]]) {
        viewController = ((UINavigationController *)viewController).topViewController;
    }
    
    if ([viewController isKindOfClass:[JCAppMenuTableViewController class]]) {
        _appMenuTableViewController = (JCAppMenuTableViewController *)viewController;
        _appMenuTableViewController.delegate = self;
    }
    else if ([viewController isKindOfClass:[JCRecentEventsTableViewController class]]) {
        _recentEventsTableViewController = (JCRecentEventsTableViewController *)viewController;
    }
    else if([viewController isKindOfClass:[UITableViewController class]]) {
        _menuTableViewController = (UITableViewController *)viewController;
        _menuTableViewController.tableView.dataSource = self.menuTableViewDataSource;
        _menuTableViewController.tableView.delegate = self.menuTableViewDelegate;
    }
}

-(void)appMenuTableViewController:(JCAppMenuTableViewController *)controller willChangeToSize:(CGSize)size
{
    self.appMenuHeightConstraint.constant = size.height;
}

@end
