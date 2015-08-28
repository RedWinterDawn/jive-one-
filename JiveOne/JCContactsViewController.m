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
#import "ContactGroup+V5Client.h"

#import "JCContactDetailViewController.h"
#import "PBX.h"
#import "User.h"

NSString *const kJCContactsViewControllerContactGroupSegueIdentifier = @"ContactGroupViewController";

@interface JCContactsViewController () <JCContactsTableViewControllerDelegate>
{
    JCContactsTableViewController *_contactsTableViewController;
}

@property (nonatomic, weak) IBOutlet UITabBar *tabBar;
@property (nonatomic, weak) IBOutlet UISearchBar *searchBar;

@end

@implementation JCContactsViewController

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    UITabBar *tabBar = self.tabBar;
    if (tabBar) {
        tabBar.selectedItem = [tabBar.items objectAtIndex:0];
    }
    
    id<JCGroupDataSource> group = self.group;
    if (group) {
        self.title = group.name;
        self.navigationItem.title = group.name;
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [super prepareForSegue:segue sender:sender];
    
    UIViewController *viewController = segue.destinationViewController;
    if ([viewController isKindOfClass:[UINavigationController class]]) {
        viewController = ((UINavigationController *)viewController).topViewController;
    }
    
    if ([viewController isKindOfClass:[JCContactsTableViewController class]]) {
        _contactsTableViewController = (JCContactsTableViewController *)viewController;
        _contactsTableViewController.delegate = self;
        
        id<JCGroupDataSource> group = self.group;
        if (group) {
            if ([group isKindOfClass:[ContactGroup class]]) {
                self.navigationItem.rightBarButtonItem = _contactsTableViewController.editButtonItem;
            }
            _contactsTableViewController.group = self.group;
        }
        _contactsTableViewController.filterType = JCContactFilterAll;
        self.searchBar.delegate = _contactsTableViewController;
        
    }
	else if ([viewController isKindOfClass:[JCContactsViewController class]])
    {
        JCContactsViewController *groupViewController = (JCContactsViewController *)viewController;
        NSIndexPath *indexPath = [_contactsTableViewController.tableView indexPathForSelectedRow];
        id object = [_contactsTableViewController objectAtIndexPath:indexPath];
        if ([object conformsToProtocol:@protocol(JCGroupDataSource)]) {
            groupViewController.group = (id<JCGroupDataSource>)object;
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
        User *user = self.userManager.pbx.user;
        
        ContactGroup *contactGroup = [ContactGroup MR_createEntityInContext:user.managedObjectContext];
        contactGroup.name = @"Test Group";
        contactGroup.user = user;
        [contactGroup markForUpdate:^(BOOL success, NSError *error) {
            NSLog(@"uploaded");
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
