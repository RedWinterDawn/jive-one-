//
//  JCContactsHomeViewController.m
//  JiveOne
//
//  Created by Eduardo  Gueiros on 11/3/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCContactsViewController.h"
#import "JCContactsTableViewController.h"
#import "JCPhoneManager.h"
#import "InternalExtensionGroup.h"
#import "JCUnknownNumber.h"
#import "ContactGroup.h"

#import "JCContactDetailViewController.h"
#import "PBX.h"
#import "User.h"

NSString *const kJCContactsViewControllerContactGroupSegueIdentifier = @"ContactGroupViewController";

@interface JCContactsViewController () <JCContactsTableViewControllerDelegate>
{
    JCContactsTableViewController *_contactsTableViewController;
}

@end

@implementation JCContactsViewController

-(void)viewDidLoad
{
    [super viewDidLoad];
    self.tabBar.selectedItem = [self.tabBar.items objectAtIndex:0];
    
    InternalExtensionGroup *contactGroup = self.contactGroup;
    if (contactGroup) {
        self.title = contactGroup.name;
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UIViewController *viewController = segue.destinationViewController;
    if ([viewController isKindOfClass:[UINavigationController class]]) {
        viewController = ((UINavigationController *)viewController).topViewController;
    }
    
    if ([viewController isKindOfClass:[JCContactsTableViewController class]]) {
        _contactsTableViewController = (JCContactsTableViewController *)viewController;
        //_contactsTableViewController.contactGroup = self.contactGroup;
        _contactsTableViewController.delegate = self;
        _contactsTableViewController.filterType = JCContactFilterAll;
        self.searchBar.delegate = _contactsTableViewController;
    }
	else if ([viewController isKindOfClass:[JCContactsViewController class]])
    {
        JCContactsViewController *contacts = (JCContactsViewController *)viewController;
        NSIndexPath *indexPath = [_contactsTableViewController.tableView indexPathForSelectedRow];
        id object = [_contactsTableViewController objectAtIndexPath:indexPath];
        if ([object isKindOfClass:[InternalExtensionGroup class]]) {
            contacts.contactGroup = (InternalExtensionGroup *)object;
        }
    }
    else if ([viewController isKindOfClass:[JCContactDetailViewController class]])
    {
        JCContactDetailViewController *detailViewController = (JCContactDetailViewController *)viewController;
        detailViewController.managedObjectContext = [NSManagedObjectContext MR_contextWithParent:[NSManagedObjectContext MR_defaultContext]];
    }
}

#pragma mark - IBActions -

-(IBAction)toggleFilterState:(id)sender
{
    NSInteger index = 0;
    if ([sender isKindOfClass:[UISegmentedControl class]]) {
        index = ((UISegmentedControl *)sender).selectedSegmentIndex;
    } else if ([sender isKindOfClass:[UITabBar class]]) {
        index = ((UITabBar *)sender).selectedItem.tag;
    } else if([sender isKindOfClass:[UITabBarItem class]]) {
        index = ((UITabBarItem *)sender).tag;
    }
    _contactsTableViewController.filterType = index;
    NSString *title =  (index == 0) ? NSLocalizedString(@"Contacts", @"Contacts") : NSLocalizedString(@"Groups", @"Contact Groups");
    self.title = title;
    self.navigationItem.title = title;
}

-(IBAction)add:(id)sender
{
//    NSString *identifier = (_contactsTableViewController.filterType == JCContactFilterAll) ? @"AddContact" : @"AddGroup" ;
//    [self performSegueWithIdentifier:identifier sender:self];
    
    // Temporary till we have more logic. The above code is the arcitecture we will want.
    
    if (_contactsTableViewController == JCContactFilterAll) {
        [self performSegueWithIdentifier:@"AddContact" sender:@"Edit"];
    } else {
        User *user = self.authenticationManager.pbx.user;
        [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
            // Simulate the creation of a group
            ContactGroup *contactGroup = [ContactGroup MR_createEntityInContext:localContext];
            contactGroup.name = @"Test Group";
            contactGroup.user = ((User * )[localContext objectWithID:user.objectID]);
        }];
    }
}


#pragma mark - Delegate Handlers -

#pragma mark UITabBarDelegate

-(void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
    [self toggleFilterState:item];
}

#pragma mark JCContactsTableViewControllerDelegate

-(void)contactsTableViewController:(JCContactsTableViewController *)contactsViewController
             didSelectGroup:(id<JCGroupDataSource>)group
{
    [self performSegueWithIdentifier:kJCContactsViewControllerContactGroupSegueIdentifier sender:self];
}

@end
