//
//  JCContactsHomeViewController.m
//  JiveOne
//
//  Created by Eduardo  Gueiros on 11/3/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCContactsHomeViewController.h"
#import "JCContactsTableViewController.h"
#import "JCSearchBar.h"





@interface JCContactsHomeViewController ()
{
    JCContactsTableViewController *contactsController;
}

@property (weak, nonatomic) IBOutlet UIView *container;


@end

@implementation JCContactsHomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tabBar.delegate = self;
    
    [self.tabBar setSelectedItem:self.tabBar.items[0]];
    
    if (!contactsController)
    {
        if (self.childViewControllers && self.childViewControllers.count > 0) {
            if ([self.childViewControllers[0] isKindOfClass:[JCContactsTableViewController class]]) {
                contactsController = (JCContactsTableViewController *)self.childViewControllers[0];
            }
        }
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
    switch (item.tag) {
        case 1:
            [self changeTableViewResults:JCContactFilterFavorites];
            break;
            
        default:
            [self changeTableViewResults:JCContactFilterAll];;
    }
}

- (void)changeTableViewResults:(JCContactFilter)type
{
    if (contactsController) {
        [contactsController changeContactType:type];
    }
}

@end
