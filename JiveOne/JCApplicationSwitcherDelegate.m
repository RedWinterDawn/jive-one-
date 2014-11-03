//
//  JCApplicationSwitcherDataSource.m
//  JCApplicationSwitcher
//
//  Created by Robert Barclay on 10/17/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCApplicationSwitcherDelegate.h"
#import "JCMenuBarButtonItem.h"

#import "JCCallHistoryViewController.h"
#import "JCVoicemailViewController.h"

#import "JCPhoneTabBarControllerDelegate.h"

#import "Voicemail.h"
#import "Call.h"

NSString *const kApplicationSwitcherLastSelectedViewControllerIdentifierKey = @"applicationSwitcherLastSelected";

NSString *const kApplicationSwitcherPhoneRestorationIdentifier = @"PhoneTabBarController";

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

-(void)applicationSwitcher:(JCApplicationSwitcherViewController *)controller shouldNavigateToRecentEvent:(RecentEvent *)recentEvent
{
    NSString *restorationIdentifier = [self applicationSwitcherRestorationIdentifierForRecentEvent:recentEvent];
    if (restorationIdentifier) {
        for (UIViewController *viewController in controller.viewControllers) {
            if ([viewController.restorationIdentifier isEqualToString:restorationIdentifier]) {
                controller.selectedViewController = viewController;
                
                // Logic for Phone Recent Events.
                if ([restorationIdentifier isEqualToString:kApplicationSwitcherPhoneRestorationIdentifier] && [viewController isKindOfClass:[UITabBarController class]]){
                    [self navigatePhoneViewController:(UITabBarController *)viewController forRecentEvent:recentEvent];
                }
                break;
            }
        }
    }
}

-(void)navigatePhoneViewController:(UITabBarController *)tabBarController forRecentEvent:(RecentEvent *)recentEvent
{
    NSString *restorationIdentifier = [self phoneTabBarControllerRestorationIdentifierForRecentEvent:recentEvent];
    for (UIViewController *controller in tabBarController.viewControllers)
    {
        if ([controller.restorationIdentifier isEqualToString:restorationIdentifier]) {
            tabBarController.selectedViewController = controller;
            
            if ([controller.restorationIdentifier isEqualToString:kJCPhoneTabBarControllerCallHistoryRestorationIdentifier] && [recentEvent isKindOfClass:[Call class]]) {
                [self navigateHistoryViewController:controller toRecentEvent:(Call *)recentEvent];
            }
            else if ([controller.restorationIdentifier isEqualToString:kJCPhoneTabBarControllerVoicemailRestorationIdentifier] && [recentEvent isKindOfClass:[Voicemail class]]) {
                [self navigateVoicemailViewController:controller toRecentEvent:(Voicemail *)recentEvent];
            }
            
            break;
        }
    }
}

-(void)navigateHistoryViewController:(UIViewController *)viewController toRecentEvent:(RecentEvent *)recentEvent
{
    if ([viewController isKindOfClass:[UINavigationController class]]) {
        viewController = ((UINavigationController *)viewController).topViewController;
        if ([viewController isKindOfClass:[JCCallHistoryViewController class]]) {
            JCCallHistoryViewController *callHistoryViewController = (JCCallHistoryViewController *)viewController;
            JCCallHistoryTableViewController *callHistoryTableViewController = callHistoryViewController.callHistoryTableViewController;
            NSIndexPath *indexPath = [callHistoryTableViewController indexPathOfObject:recentEvent];
            
            [callHistoryTableViewController.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
        }
    }
}

-(void)navigateVoicemailViewController:(UIViewController *)viewController toRecentEvent:(Voicemail *)recentEvent
{
    if ([viewController isKindOfClass:[UINavigationController class]]) {
        viewController = ((UINavigationController *)viewController).topViewController;
        if ([viewController isKindOfClass:[JCVoicemailViewController class]]) {
            JCVoicemailViewController *voicemailViewController = (JCVoicemailViewController *)viewController;
            [voicemailViewController loadVoicemail:recentEvent];
        }
    }
}

-(NSString *)applicationSwitcherRestorationIdentifierForRecentEvent:(RecentEvent *)recentEvent
{
    if ([recentEvent isKindOfClass:[Voicemail class]] || [recentEvent isKindOfClass:[Call class]]) {
        return kApplicationSwitcherPhoneRestorationIdentifier;
    }
    return nil;
}

-(NSString *)phoneTabBarControllerRestorationIdentifierForRecentEvent:(RecentEvent *)recentEvent
{
    if ([recentEvent isKindOfClass:[Voicemail class]]) {
        return kJCPhoneTabBarControllerVoicemailRestorationIdentifier;
    }
    else if ([recentEvent isKindOfClass:[Call class]]){
        return kJCPhoneTabBarControllerCallHistoryRestorationIdentifier;
    }
    return nil;
}

-(BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController
{
    // Default select the Dialer view if the phone controller is selected from the application switcher;
    if ([viewController.restorationIdentifier isEqualToString:kApplicationSwitcherPhoneRestorationIdentifier]) {
        if ([viewController isKindOfClass:[UITabBarController class]]) {
            UITabBarController *phoneTabBarController = (UITabBarController *)viewController;
            for (UIViewController *controller in phoneTabBarController.viewControllers) {
                if ([controller.restorationIdentifier isEqualToString:kJCPhoneTabBarControllerDialerRestorationIdentifier]) {
                    phoneTabBarController.selectedViewController = controller;
                }
            }
        }
    }
    return YES;
}

-(void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
{
    if (viewController.restorationIdentifier) {
        self.lastSelectedViewControllerIdentifier = viewController.restorationIdentifier;
    }
}

@end
