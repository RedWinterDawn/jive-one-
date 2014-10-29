//
//  JCApplicationSwitcherDataSource.m
//  JCApplicationSwitcher
//
//  Created by Robert Barclay on 10/17/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCApplicationSwitcherDelegate.h"
#import "JCMenuBarButtonItem.h"

NSString *const kApplicationSwitcherLastSelectedViewControllerIdentifierKey = @"applicationSwitcherLastSelected";

@interface JCApplicationSwitcherDelegate ()

@property (nonatomic, strong) NSString *lastSelectedViewControllerIdentifier;

@end


@implementation JCApplicationSwitcherDelegate

+(void)reset
{
    JCApplicationSwitcherDelegate *obj = [[JCApplicationSwitcherDelegate alloc] init];
    obj.lastSelectedViewControllerIdentifier = nil;
}

#pragma mark - Setters -

-(void)setLastSelectedViewControllerIdentifier:(NSString *)lastSelectedViewControllerIdentifier
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue:lastSelectedViewControllerIdentifier forKey:kApplicationSwitcherLastSelectedViewControllerIdentifierKey];
    [defaults synchronize];
}

#pragma mark - Getters -

-(NSString *)lastSelectedViewControllerIdentifier
{
    return [[NSUserDefaults standardUserDefaults] valueForKey:kApplicationSwitcherLastSelectedViewControllerIdentifierKey];
}

#pragma mark - Delegate Handlers -

#pragma mark JCApplicationSwitcherViewControllerDelegate

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
    NSString *identifier = self.lastSelectedViewControllerIdentifier;
    for (UIViewController *viewController in controller.viewControllers) {
        if ([viewController.restorationIdentifier isEqualToString:identifier]) {
            return viewController;
        }
    }
    return nil;
}

-(BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController
{
    return YES;
}

-(void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
{
    if (viewController.restorationIdentifier) {
        self.lastSelectedViewControllerIdentifier = viewController.restorationIdentifier;
    }
}

@end
