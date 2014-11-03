//
//  JCApplicationSwitcherViewController.h
//  JCApplicationSwitcher
//
//  Created by Robert Barclay on 10/17/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

@import UIKit;

#import "RecentEvent.h"

@class JCApplicationSwitcherViewController;

@protocol JCApplicationSwitcherDelegate <UITabBarControllerDelegate>

-(UIBarButtonItem *)applicationSwitcherController:(JCApplicationSwitcherViewController *)controller identifier:(NSString *)identifier;

@optional
-(NSArray *)applicationSwitcherController:(JCApplicationSwitcherViewController *)controller willLoadViewControllers:(NSArray *)viewControllers;
-(UIViewController *)applicationSwitcherLastSelectedViewController:(JCApplicationSwitcherViewController *)controller;
-(UITableViewCell *)applicationSwitcherController:(JCApplicationSwitcherViewController *)controller tableView:(UITableView *)tableView cellForTabBarItem:(UITabBarItem *)tabBarItem identifier:(NSString *)identifier;
-(void)applicationSwitcher:(JCApplicationSwitcherViewController *)controller shouldNavigateToRecentEvent:(RecentEvent *)recentEvent;

@end

@interface JCApplicationSwitcherViewController : UITabBarController

// Tab Bar Controller DataSource.
@property (nonatomic, weak) IBOutlet id <JCApplicationSwitcherDelegate> delegate;

// Configurable Properties
@property (nonatomic, strong) NSString *menuViewControllerStoryboardIdentifier;
@property (nonatomic, strong) NSString *activityViewControllerStoryboardIdentifier;

// Shows the menu
-(IBAction)showMenu:(id)sender;

@end
