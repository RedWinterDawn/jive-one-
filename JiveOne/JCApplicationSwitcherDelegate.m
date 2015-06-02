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
#import "JCCallHistoryViewController_iPhone.h"
#import "JCRecentLineEventsTableViewController.h"
#import "JCConversationsTableViewController.h"

#import "JCPhoneTabBarControllerDelegate.h"

#import "JCConversationGroupObject.h"
#import "Voicemail.h"
#import "Call.h"
#import "Line.h"
#import "PBX.h"

#import "JCAuthenticationManager.h"
#import "JCAppSettings.h"
#import "JCStoryboardLoaderViewController.h"

NSString *const kApplicationSwitcherPhoneRestorationIdentifier      = @"PhoneTabBarController";
NSString *const kApplicationSwitcherMessagesRestorationIdentifier   = @"MessagesNavigationController";
NSString *const kApplicationSwitcherContactsRestorationIdentifier   = @"ContactsNavigationController";
NSString *const kApplicationSwitcherSettingsRestorationIdentifier   = @"SettingsNavigationController";

@interface JCApplicationSwitcherDelegate ()
{
    JCApplicationSwitcherViewController *_applicationSwitcher;
    NSArray *_viewControllers;
    JCAppSettings *_appSettings;
    JCAuthenticationManager *_authenticationManager;
}

@end

@implementation JCApplicationSwitcherDelegate

-(instancetype)initWithAppsSettings:(JCAppSettings *)appSettings authenticationManager:(JCAuthenticationManager *)authenticationManager
{
    self = [super init];
    if (self) {
        _appSettings = appSettings;
        _authenticationManager = authenticationManager;
        
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(reset:) name:kJCAuthenticationManagerUserLoggedOutNotification object:authenticationManager];
        [center addObserver:self selector:@selector(reload:) name:kJCAuthenticationManagerUserLoadedMinimumDataNotification object:authenticationManager];
        [center addObserver:self selector:@selector(reload:) name:kJCAuthenticationManagerLineChangedNotification object:authenticationManager];
    }
    return self;
}

-(instancetype)init
{
    return [self initWithAppsSettings:[JCAppSettings sharedSettings]
                authenticationManager:[JCAuthenticationManager sharedInstance]];
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)reset:(NSNotification *)notification
{
    _appSettings.appSwitcherLastSelectedViewControllerIdentifier = nil;
    if (_applicationSwitcher) {
        _applicationSwitcher.selectedViewController = nil;
    }
}

-(void)reload:(NSNotification *)notification
{
    _applicationSwitcher.viewControllers = [self determineControllersAccess:_viewControllers.mutableCopy];
}

-(NSMutableArray *)determineControllersAccess:(NSMutableArray *)viewControllers
{
    PBX *pbx = _authenticationManager.line.pbx;
    if (!pbx) {
        return viewControllers;
    }
    
    for (UIViewController *viewController in _viewControllers) {
        NSString *identifier = viewController.restorationIdentifier;
        
        // Feature Flag SMS. If pbx's DIDs are not SMS enabled, remove from view controllers.
        if ([identifier isEqualToString:kApplicationSwitcherMessagesRestorationIdentifier]) {
            if (!pbx.smsEnabled) {
                [viewControllers removeObject:viewController];
            }
        }
    }
    return viewControllers;
}

#pragma mark - Privete -

-(NSString *)applicationSwitcherRestorationIdentifierForRecentEvent:(id)recentEvent
{
    if ([recentEvent isKindOfClass:[Voicemail class]] || [recentEvent isKindOfClass:[Call class]]) {
        return kApplicationSwitcherPhoneRestorationIdentifier;
    }
    else if ([recentEvent conformsToProtocol:@protocol(JCConversationGroupObject)]) {
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
        if ([viewController isKindOfClass:[JCCallHistoryViewController_iPhone class]]) {
            JCCallHistoryViewController_iPhone *callHistoryViewController = (JCCallHistoryViewController_iPhone *)viewController;
            dispatch_async(dispatch_get_main_queue(), ^{
                __block JCCallHistoryTableViewController *callHistoryTableViewController = callHistoryViewController.callHistoryTableViewController;
                NSIndexPath *indexPath = [callHistoryTableViewController indexPathOfObject:recentEvent];
                UITableViewCell *cell = [callHistoryTableViewController.tableView cellForRowAtIndexPath:indexPath];
                [callHistoryTableViewController performSegueWithIdentifier:@"CallHistoryDetailNoAnimation" sender:cell];
            });
        }
    }
}

-(void)navigateVoicemailViewController:(UIViewController *)viewController toRecentEvent:(Voicemail *)recentEvent
{
    if ([viewController isKindOfClass:[UINavigationController class]]) {
        viewController = ((UINavigationController *)viewController).topViewController;
        if ([viewController isKindOfClass:[JCRecentLineEventsTableViewController class]]) {
            JCRecentLineEventsTableViewController *voicemailViewController = (JCRecentLineEventsTableViewController *)viewController;
            NSIndexPath *indexPath = [voicemailViewController indexPathOfObject:recentEvent];
            UITableViewCell *cell = [voicemailViewController.tableView cellForRowAtIndexPath:indexPath];
            [voicemailViewController performSegueWithIdentifier:@"VoicemailDetailNoAnimation" sender:cell];
        }
    }
}

#pragma mark - Delegate Handlers -

#pragma mark JCApplicationSwitcherViewControllerDelegate

-(NSArray *)applicationSwitcherController:(JCApplicationSwitcherViewController *)controller
                  willLoadViewControllers:(NSArray *)viewControllers
{
    _applicationSwitcher = controller;
    _viewControllers = [viewControllers copy];
    return [self determineControllersAccess:viewControllers.mutableCopy];
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
    NSString *identifier = _appSettings.appSwitcherLastSelectedViewControllerIdentifier;
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
        if ([viewController isKindOfClass:[JCStoryboardLoaderViewController class]]) {
            viewController = ((JCStoryboardLoaderViewController *)viewController).embeddedViewController;
        }
        
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
        _appSettings.appSwitcherLastSelectedViewControllerIdentifier = viewController.restorationIdentifier;
    }
}

/**
 *  Delegate method notifying us that the application switcher should respond to a recent event
 *  selection.
 */
-(void)applicationSwitcher:(JCApplicationSwitcherViewController *)appSwitcherController shouldNavigateToRecentEvent:(id)recentEvent
{
    NSString *restorationIdentifier = [self applicationSwitcherRestorationIdentifierForRecentEvent:recentEvent];
    if (restorationIdentifier) {
        for (UIViewController *viewController in appSwitcherController.viewControllers) {
            UIViewController *controller = viewController;
            
            if ([viewController.restorationIdentifier isEqualToString:restorationIdentifier]) {
                appSwitcherController.selectedViewController = viewController;
                
                if ([controller isKindOfClass:[JCStoryboardLoaderViewController class]]) {
                    controller = ((JCStoryboardLoaderViewController *)controller).embeddedViewController;
                }
                
                // Logic for Phone Recent Events.
                if ([restorationIdentifier isEqualToString:kApplicationSwitcherPhoneRestorationIdentifier] && [controller isKindOfClass:[UITabBarController class]]){
                    [self navigatePhoneViewController:(UITabBarController *)controller forRecentEvent:recentEvent];
                }
                else if ([restorationIdentifier isEqualToString:kApplicationSwitcherMessagesRestorationIdentifier] && [controller isKindOfClass:[UINavigationController class]] && [recentEvent conformsToProtocol:@protocol(JCConversationGroupObject)]) {
                    UINavigationController *navigationController = (UINavigationController *)controller;
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
