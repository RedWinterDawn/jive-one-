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
#import "JCCallerViewController.h"

@interface JCContactsViewController () <ABPeoplePickerNavigationControllerDelegate>
{
    JCContactsTableViewController *_contactsTableViewController;
    NSString *_dialString;
}

@end

@implementation JCContactsViewController

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tabBar.selectedItem = [self.tabBar.items objectAtIndex:0];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (_dialString) {
        [self performSegueWithIdentifier:@"LocalContactsClickToCall" sender:self];
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UIViewController *viewController = segue.destinationViewController;
    if ([viewController isKindOfClass:[JCContactsTableViewController class]]) {
        _contactsTableViewController = (JCContactsTableViewController *)viewController;
        _contactsTableViewController.filterType = JCContactFilterAll;
        self.searchBar.delegate = _contactsTableViewController;
    }
    else if ([viewController isKindOfClass:[JCCallerViewController class]])
    {
        JCCallerViewController *caller = (JCCallerViewController *)viewController;
        caller.dialString = _dialString;
        _dialString = nil;
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

- (void)didSelectPerson:(ABRecordRef)person identifier:(ABMultiValueIdentifier)identifier
{
    NSString *phoneNumber = nil;
    ABMultiValueRef phones = ABRecordCopyValue(person, kABPersonPhoneProperty);
    if (phones)
    {
        if (ABMultiValueGetCount(phones) > 0)
        {
            CFIndex index = 0;
            if (identifier != kABMultiValueInvalidIdentifier)
            {
                index = ABMultiValueGetIndexForIdentifier(phones, identifier);
            }
            phoneNumber = CFBridgingRelease(ABMultiValueCopyValueAtIndex(phones, index));

            NSString *strippedString = [[phoneNumber componentsSeparatedByCharactersInSet:[[NSCharacterSet characterSetWithCharactersInString:@"1234567890*"] invertedSet]]componentsJoinedByString:@""];
            phoneNumber = strippedString;

            NSLog(@"phoneNumber: %@", phoneNumber);
        }
        CFRelease(phones);
    }
    
    _dialString = phoneNumber;
    NSLog(@"%@", _dialString);
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

@end
