//
//  JCContactsHomeViewController.m
//  JiveOne
//
//  Created by Eduardo  Gueiros on 11/3/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

@import AddressBook;
@import AddressBookUI;

#import "JCContactsViewController.h"
#import "JCContactsTableViewController.h"
#import "JCPhoneManager.h"
#import "ContactGroup.h"
#import "JCUnknownNumber.h"
#import "JCAddressBookNumber.h"
#import "JCAddressBookPerson.h"

NSString *const kJCContactsViewControllerContactGroupSegueIdentifier = @"ContactGroupViewController";

@interface JCContactsViewController () <ABPeoplePickerNavigationControllerDelegate, JCContactsTableViewControllerDelegate>
{
    JCContactsTableViewController *_contactsTableViewController;
    JCAddressBookNumber *_phoneNumber;
}

@end

@implementation JCContactsViewController

-(void)viewDidLoad
{
    [super viewDidLoad];
    self.tabBar.selectedItem = [self.tabBar.items objectAtIndex:0];
    
    ContactGroup *contactGroup = self.contactGroup;
    if (contactGroup) {
        self.title = contactGroup.name;
    }
    
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (_phoneNumber) {
        [self dialPhoneNumber:_phoneNumber
                    usingLine:self.authenticationManager.line
                       sender:nil
                   completion:^(BOOL success, NSError *error) {
                       _phoneNumber = nil;
                   }];
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UIViewController *viewController = segue.destinationViewController;
    if ([viewController isKindOfClass:[JCContactsTableViewController class]]) {
        _contactsTableViewController = (JCContactsTableViewController *)viewController;
        _contactsTableViewController.contactGroup = self.contactGroup;
        _contactsTableViewController.delegate = self;
        _contactsTableViewController.filterType = JCContactFilterAll;
        self.searchBar.delegate = _contactsTableViewController;
    }
	else if ([viewController isKindOfClass:[JCContactsViewController class]])
    {
        JCContactsViewController *contacts = (JCContactsViewController *)viewController;
        NSIndexPath *indexPath = [_contactsTableViewController.tableView indexPathForSelectedRow];
        id object = [_contactsTableViewController objectAtIndexPath:indexPath];
        if ([object isKindOfClass:[ContactGroup class]]) {
            contacts.contactGroup = (ContactGroup *)object;
        }
    }
}

#pragma mark - Private -

// Called when users tap "Display Picker" in the application. Displays a list of contacts and allows users to select a contact from that list.
// The application only shows the phone, email, and birthdate information of the selected contact.
-(void)showPeoplePickerController
{
    ABPeoplePickerNavigationController *picker = [[ABPeoplePickerNavigationController alloc] init];
    picker.peoplePickerDelegate = self;
    
    // Display only a person's phone, email, and birthdate
    NSArray *displayedItems = [NSArray arrayWithObjects:[NSNumber numberWithInt:kABPersonPhoneProperty],
                               [NSNumber numberWithInt:kABPersonEmailProperty],
                               [NSNumber numberWithInt:kABPersonBirthdayProperty], nil];
    
    
    picker.displayedProperties = displayedItems;
    
    // Show the picker
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)didSelectPerson:(ABRecordRef)personRef identifier:(ABMultiValueIdentifier)identifier
{
    JCAddressBookPerson *person = [JCAddressBookPerson addressBookPersonWithABRecordRef:personRef];
    JCAddressBookNumber *phoneNumber = [person addressBookNumberForIdentifier:identifier];
    _phoneNumber = phoneNumber;
}

-(IBAction)toggleFilterState:(id)sender
{
    if ([sender isKindOfClass:[UISegmentedControl class]])
    {
        UISegmentedControl *segmentedControl = (UISegmentedControl *)sender;
        switch (segmentedControl.selectedSegmentIndex) {
            case 1:
            {
                _contactsTableViewController.filterType = JCContactFilterGrouped;
                break;
            }
            case 2:
            {
                [self showPeoplePickerController];
                break;
            }
            default:
                _contactsTableViewController.filterType = JCContactFilterAll;
                break;
        }
    }
}


#pragma mark - Delegate Handlers -

#pragma mark UITabBarDelegate

-(void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
    switch (tabBar.selectedItem.tag) {
        case 1:
            _contactsTableViewController.filterType = JCContactFilterFavorites;
            break;
            
        case 2:
            _contactsTableViewController.filterType = JCContactFilterGrouped;
            break;
            
        case 3:
            [self showPeoplePickerController];
            tabBar.selectedItem = nil;
            break;
            
        default:
            _contactsTableViewController.filterType = JCContactFilterAll;
            break;
    }
}

#pragma mark Show all contacts

#pragma mark ABPeoplePickerNavigationControllerDelegate methods

// On iOS 8.0, a selected person and property is returned with this method.
- (void)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker didSelectPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier
{
    [self didSelectPerson:person identifier:identifier];
}

#pragma clang diagnostic ignored "-Wdeprecated-implementations" // iOS 7 backwards compatibility.
- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier
{
    [self didSelectPerson:person identifier:identifier];
    [peoplePicker dismissViewControllerAnimated:YES completion:NULL];
    return NO;
}

// Dismisses the people picker and shows the application when users tap Cancel.
- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker;
{
    [peoplePicker dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark JCContactsTableViewControllerDelegate

-(void)contactsTableViewController:(JCContactsTableViewController *)contactsViewController didSelectContactGroup:(ContactGroup *)contactGroup
{
    [self performSegueWithIdentifier:kJCContactsViewControllerContactGroupSegueIdentifier sender:self];
}

@end
