//
//  JCApplicationSwitcherDataSource.m
//  JCApplicationSwitcher
//
//  Created by Robert Barclay on 10/17/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCApplicationSwitcherDelegate.h"
#import "JCMenuBarButtonItem.h"

@implementation JCApplicationSwitcherDelegate

-(NSArray *)applicationSwitcherController:(JCApplicationSwitcherViewController *)controller willLoadViewControllers:(NSArray *)viewControllers
{
    return viewControllers;
}

-(UIBarButtonItem *)applicationSwitcherController:(JCApplicationSwitcherViewController *)controller identifier:(NSString *)identifier;
{
    return [[JCMenuBarButtonItem alloc] initWithTarget:controller action:@selector(showMenu:)];
}

-(UIViewController *)applicationSwitcherLastSelectedViewController:(JCApplicationSwitcherViewController *)controller
{
    return [controller.viewControllers firstObject];
}

-(void)applicationSwitcherController:(JCApplicationSwitcherViewController *)controller willSelectViewController:(UIViewController *)viewController
{
    
}

-(void)applicationSwitcherController:(JCApplicationSwitcherViewController *)controller didSelectViewController:(UIViewController *)viewController
{
    
}


@end
