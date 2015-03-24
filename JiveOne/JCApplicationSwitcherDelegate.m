//
//  JCApplicationSwitcherDataSource.m
//  JCApplicationSwitcher
//
//  Created by Robert Barclay on 10/17/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCApplicationSwitcherDelegate.h"
#import "JCMenuBarButtonItem.h"

// View Controllers
#import "JCApplicationSwitcherViewController.h"
#import "JCCallHistoryViewController.h"
#import "JCVoicemailViewController.h"
#import "JCConversationsTableViewController.h"

#import "JCPhoneTabBarControllerDelegate.h"

#import "Voicemail.h"
#import "Call.h"
#import "JCConversationGroup.h"

#import "JCAuthenticationManager.h"

NSString *const kApplicationSwitcherLastSelectedViewControllerIdentifierKey = @"applicationSwitcherLastSelected";

NSString *const kApplicationSwitcherPhoneRestorationIdentifier      = @"PhoneTabBarController";
NSString *const kApplicationSwitcherMessagesRestorationIdentifier      = @"MessagesNavigationController";
NSString *const kApplicationSwitcherContactsRestorationIdentifier   = @"ContactsNavigationController";
NSString *const kApplicationSwitcherSettingsRestorationIdentifier   = @"SettingsNavigationController";

@interface JCApplicationSwitcherDelegate ()
{
    JCApplicationSwitcherViewController *_applicationSwitcher;
}

@property (nonatomic, strong) NSString *lastSelectedViewControllerIdentifier;

@end

@implementation JCApplicationSwitcherDelegate

-(instancetype)init
{
    self = [super init];
    if (self) {
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(reset:) name:kJCAuthenticationManagerUserLoggedOutNotification object:[JCAuthenticationManager sharedInstance]];
    }
    return self;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)reset:(NSNotification *)notification
{
    self.lastSelectedViewControllerIdentifier = nil;
    if (_applicationSwitcher) {
        _applicationSwitcher.selectedViewController = nil;
    }
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

#pragma mark - Privete -

-(NSString *)applicationSwitcherRestorationIdentifierForRecentEvent:(id)recentEvent
{
    if ([recentEvent isKindOfClass:[Voicemail class]] || [recentEvent isKindOfClass:[Call class]]) {
        return kApplicationSwitcherPhoneRestorationIdentifier;
    }
    else if ([recentEvent isKindOfClass:[JCConversationGroup class]]) {
        return kApplicationSwitcherMessagesRestorationIdentifier;
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
            voicemailViewController.voicemail = recentEvent;
        }
    }
}

#pragma mark - Delegate Handlers -

#pragma mark JCApplicationSwitcherViewControllerDelegate

-(NSArray *)applicationSwitcherController:(JCApplicationSwitcherViewController *)controller
                  willLoadViewControllers:(NSArray *)viewControllers
{
    _applicationSwitcher = controller;
    return viewControllers;
}

-(UIBarButtonItem *)applicationSwitcherController:(JCApplicationSwitcherViewController *)controller
                                       identifier:(NSString *)identifier;
{
    return [[JCMenuBarButtonItem alloc] initWithTarget:controller action:@selector(showMenu:)];
}

-(UITableViewCell *)applicationSwitcherController:(JCApplicationSwitcherViewController *)controller
                                        tableView:(UITableView *)tableView
                                cellForTabBarItem:(UITabBarItem *)tabBarItem
                                       identifier:(NSString *)identifier
{
    if ([identifier isEqualToString:kApplicationSwitcherPhoneRestorationIdentifier]) {
        static NSString *phoneResueIdentifier = @"PhoneCell";
        UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:phoneResueIdentifier];
        cell.textLabel.text = tabBarItem.title;
        cell.imageView.image = tabBarItem.image;
        return cell;
    }
    else if ([identifier isEqualToString:kApplicationSwitcherMessagesRestorationIdentifier]) {
        static NSString *messagesResueIdentifier = @"MessageCell";
        UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:messagesResueIdentifier];
        cell.textLabel.text = tabBarItem.title;
        cell.imageView.image = tabBarItem.image;
        return cell;
    }
 
    static NSString *resueIdentifier = @"MenuCell";
    UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:resueIdentifier];
    cell.textLabel.text = tabBarItem.title;
    cell.imageView.image = tabBarItem.image;
    return cell;
}

/**
 * From the list of view controllers, select the last selected view controller.
 */
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

/**
 *  Asked right before an application switcher view controller is selected.
 */
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

/**
 *  Delegate Method called when application switcher view controller was selected. If the view 
 *  controller has a restoration identifier, we save the restoration identifer, remebering which 
 *  view controller was last selected.
 */
-(void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
{
    if (viewController.restorationIdentifier) {
        self.lastSelectedViewControllerIdentifier = viewController.restorationIdentifier;
    }
}

/**
 *  Delegate method notifying us that the application switcher should respond to a recent event
 *  selection.
 */
-(void)applicationSwitcher:(JCApplicationSwitcherViewController *)controller shouldNavigateToRecentEvent:(id)recentEvent
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
                else if ([restorationIdentifier isEqualToString:kApplicationSwitcherMessagesRestorationIdentifier] && [viewController isKindOfClass:[UINavigationController class]] && [recentEvent isKindOfClass:[JCConversationGroup class]]) {
                    UINavigationController *navigationController = (UINavigationController *)viewController;
                    [navigationController popToRootViewControllerAnimated:NO];
                    JCConversationsTableViewController *conversationViewController = (JCConversationsTableViewController *)navigationController.topViewController;
                    NSIndexPath *indexPath = [conversationViewController indexPathOfObject:recentEvent];
                    UITableViewCell *cell = [conversationViewController.tableView cellForRowAtIndexPath:indexPath];
                    [conversationViewController performSegueWithIdentifier:@"AppSwitcherLoadMessageGroup" sender:cell];
                }
                break;
            }
        }
    }
}

@end
