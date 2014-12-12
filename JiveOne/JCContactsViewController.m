//
//  JCContactsHomeViewController.m
//  JiveOne
//
//  Created by Eduardo  Gueiros on 11/3/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCContactsViewController.h"
#import "JCContactsTableViewController.h"

@interface JCContactsViewController ()
{
    JCContactsTableViewController *_contactsTableViewController;
}

@end

@implementation JCContactsViewController

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tabBar.selectedItem = [self.tabBar.items objectAtIndex:0];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UIViewController *viewController = segue.destinationViewController;
    if ([viewController isKindOfClass:[JCContactsTableViewController class]]) {
        _contactsTableViewController = (JCContactsTableViewController *)viewController;
        _contactsTableViewController.filterType = JCContactFilterAll;
        self.searchBar.delegate = _contactsTableViewController;
    }
}

#pragma mark - Delegate Handlers -

#pragma mark UITabBarDelegate

-(void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
    switch (tabBar.selectedItem.tag) {
        case 1:
            _contactsTableViewController.filterType = JCContactFilterFavorites;
            break;
        case 2:
            _contactsTableViewController.filterType = JCExternalContacts;
            break;
            
        default:
            _contactsTableViewController.filterType = JCContactFilterAll;
            break;
    }
}

@end
