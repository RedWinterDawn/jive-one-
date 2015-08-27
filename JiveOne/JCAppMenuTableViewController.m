//
//  JCAppMenuViewController.m
//  JiveOne
//
//  Created by Robert Barclay on 4/21/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCAppMenuTableViewController.h"

// View Controllers
#import "JCStoryboardLoaderViewController.h"

// Managers
#import <JCPhoneModule/JCPhoneManager.h>

// Managed objects
#import "PBX.h"

// Objects
#import "JCAppSettings.h"

NSString *const kApplicationSwitcherPhoneIdentifier      = @"Phone";
NSString *const kApplicationSwitcherMessagesIdentifier   = @"Messages";
NSString *const kApplicationSwitcherContactsIdentifier   = @"Contacts";
NSString *const kApplicationSwitcherSettingsIdentifier   = @"Settings";


@implementation JCAppMenuTableViewController

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    
    JCAuthManager *authenticationManager = self.authenticationManager;
    
    [center addObserver:self selector:@selector(reset:) name:kJCAuthenticationManagerUserLoggedOutNotification object:authenticationManager];
    [center addObserver:self selector:@selector(reload:) name:kJCAuthenticationManagerUserLoadedMinimumDataNotification object:authenticationManager];
    [center addObserver:self selector:@selector(reload:) name:kJCAuthenticationManagerLineChangedNotification object:authenticationManager];
    [center addObserver:self selector:@selector(showCall:) name:kJCPhoneManagerShowCallsNotification object:self.phoneManager];
    
    [self performSelectorOnMainThread:@selector(loadLastSelected) withObject:nil waitUntilDone:NO];
    [self reload:nil];
}

-(void)loadLastSelected
{
    NSString *identifier = self.appSettings.appSwitcherLastSelectedViewControllerIdentifier;
    if(!identifier)
        identifier = [self identifierForTableViewCell:self.phoneCell];
    [self selectCellUsingIdentifier:identifier];
}

-(void)selectCellUsingIdentifier:(NSString *)identifier
{
    if (!identifier) {
        return;
    }
    
    UITableView *tableView = self.tableView;
    UITableViewCell *tableViewCell = [self cellForIdentifier:identifier];
    NSString *sanityCheck = [self identifierForTableViewCell:tableViewCell];
    if (![identifier isEqualToString:sanityCheck]) {
        identifier = sanityCheck;
    }

    NSIndexPath *indexPath = [tableView indexPathForCell:tableViewCell];
    [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    [self performSegueWithIdentifier:identifier sender:tableViewCell];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    UIViewController *viewController = segue.destinationViewController;
    
    if ([viewController isKindOfClass:[JCStoryboardLoaderViewController class]]) {
        viewController = ((JCStoryboardLoaderViewController *)viewController).embeddedViewController;
    }
    
    if ([viewController isKindOfClass:[UISplitViewController class]]) {
        UISplitViewController *splitViewController = (UISplitViewController *)viewController;
        viewController = splitViewController.viewControllers.firstObject;
    }
    
    if ([viewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = (UINavigationController *)viewController;
        UIColor *barColor = navigationController.navigationBar.barTintColor;
        self.navigationController.navigationBar.barTintColor = barColor;
    }
}

#pragma mark - Notification Handlers -

-(void)reload:(NSNotification *)notification
{
    [self cell:self.messageCell setHidden:!self.authenticationManager.pbx.smsEnabled];
    [self reloadDataAnimated:NO];
    
    CGSize size = self.tableView.contentSize;
    [_delegate appMenuTableViewController:self willChangeToSize:size];
}

-(void)reset:(NSNotification *)notification
{
    self.appSettings.appSwitcherLastSelectedViewControllerIdentifier = nil;
}

-(void)showCall:(NSNotification *)notification
{
    UITableView *tableView = self.tableView;
    NSIndexPath *indexPath = [tableView indexPathForSelectedRow];
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    UITableViewCell *phoneCell = self.phoneCell;
    
    // If we are currently on that cell, we do not need to change to that cell, so exit.
    if ([cell isEqual:phoneCell]) {
        return;
    }
    
    [self selectCellUsingIdentifier:kApplicationSwitcherPhoneIdentifier];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    NSString *identifier = [self identifierForTableViewCell:cell];
    self.appSettings.appSwitcherLastSelectedViewControllerIdentifier = identifier;
}

-(NSString *)identifierForTableViewCell:(UITableViewCell *)cell
{
    if ([cell isEqual:self.settingsViewCell]) {
        return kApplicationSwitcherSettingsIdentifier;
    }
    else if([cell isEqual:self.messageCell]) {
        return kApplicationSwitcherMessagesIdentifier;
    }
    else if ([cell isEqual:self.contactsCell]) {
        return kApplicationSwitcherContactsIdentifier;
    }
    else {
        return kApplicationSwitcherPhoneIdentifier;
    }
}

-(UITableViewCell *)cellForIdentifier:(NSString *)identifier
{
    if ([identifier isEqualToString:kApplicationSwitcherSettingsIdentifier]) {
        return self.settingsViewCell;
    } else if ([identifier isEqualToString:kApplicationSwitcherMessagesIdentifier]) {
        return self.messageCell;
    } else if ([identifier isEqualToString:kApplicationSwitcherContactsIdentifier]) {
        return self.contactsCell;
    } else {
        return self.phoneCell;
    }
}

@end
