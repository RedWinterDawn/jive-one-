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

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UIViewController *viewController = segue.destinationViewController;
    if ([viewController isKindOfClass:[JCContactsTableViewController class]]) {
        _contactsTableViewController = (JCContactsTableViewController *)viewController;
        [_contactsTableViewController changeContactType:JCContactFilterAll];
    }
}

#pragma mark - Delegate Handlers -

#pragma mark UITabBarDelegate

-(void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
    switch (tabBar.selectedItem.tag) {
        case 1:
            [_contactsTableViewController changeContactType:JCContactFilterFavorites];
            break;
            
        default:
            [_contactsTableViewController changeContactType:JCContactFilterAll];
            break;
    }
}

@end
