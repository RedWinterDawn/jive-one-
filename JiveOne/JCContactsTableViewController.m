//
//  JCContactsTableViewController.m
//  JiveOne
//
//  Created by Eduardo  Gueiros on 10/30/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCContactsTableViewController.h"
#import "JCCallerViewController.h"

#import "Lines+Custom.h"
#import "JCPersonCell.h"
#import "JasmineSocket.h"
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>


@interface JCContactsTableViewController()  <JCCallerViewControllerDelegate, ABPeoplePickerNavigationControllerDelegate, ABPersonViewControllerDelegate>
{
    NSString *_searchText;
    NSMutableDictionary *lineSubcription;
}


@property (nonatomic, weak) NSPredicate *predicate;
@property (nonatomic, assign) ABAddressBookRef addressBook;
@property (nonatomic, strong) NSMutableArray *LocalContacts;

@property (nonatomic, strong) ABPeoplePickerNavigationController *addressBookController;

-(void)showAddressBook;
@end

@implementation JCContactsTableViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subscribeToLinePresence:) name:kSocketDidOpen object:nil];
    if ([JasmineSocket sharedInstance].socket.readyState == SR_OPEN) {
        [self subscribeToLinePresence:nil];
    }
    else {
        [[JasmineSocket sharedInstance] initSocket];
    }
//    _addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
//    [self checkAddressBookAccess];
    
}


-(void)showAddressBook{
    _addressBookController = [[ABPeoplePickerNavigationController alloc] init];
    [_addressBookController setPeoplePickerDelegate:self];
    [self presentViewController:_addressBookController animated:YES completion:nil];
}

-(BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person{
    NSMutableDictionary *contactInfoDict = [[NSMutableDictionary alloc]
                                            initWithObjects:@[@"", @"", @"", @"", @"", @"", @"", @"", @""]
                                            forKeys:@[@"firstName", @"lastName", @"mobileNumber", @"homeNumber", @"homeEmail", @"workEmail", @"address", @"zipCode", @"city"]];
    
    CFTypeRef generalCFObject;
    generalCFObject = ABRecordCopyValue(person, kABPersonFirstNameProperty);
    //get first name of contact if it exsists
    if (generalCFObject) {
        [contactInfoDict setObject:(__bridge NSString *)generalCFObject forKey:@"firstName"];
        CFRelease(generalCFObject);
    }
    //get last name if exsists
    generalCFObject = ABRecordCopyValue(person, kABPersonLastNameProperty);
    if (generalCFObject) {
        [contactInfoDict setObject:(__bridge NSString *)generalCFObject forKey:@"lastName"];
        CFRelease(generalCFObject);
    }
    
    ABMultiValueRef phonesRef = ABRecordCopyValue(person, kABPersonPhoneProperty);
    // get all phone numbers accociated with this contact
    for (int i=0; i < ABMultiValueGetCount(phonesRef); i++) {
        CFStringRef currentPhoneLabel = ABMultiValueCopyLabelAtIndex(phonesRef, i);
        CFStringRef currentPhoneValue = ABMultiValueCopyValueAtIndex(phonesRef, i);
        
        if (CFStringCompare(currentPhoneLabel, kABPersonPhoneMobileLabel, 0) == kCFCompareEqualTo) {
            [contactInfoDict setObject:(__bridge NSString *)currentPhoneValue forKey:@"mobileNumber"];
        }
        
        if (CFStringCompare(currentPhoneLabel, kABHomeLabel, 0) == kCFCompareEqualTo) {
            [contactInfoDict setObject:(__bridge NSString *)currentPhoneValue forKey:@"homeNumber"];
        }
        
        CFRelease(currentPhoneLabel);
        CFRelease(currentPhoneValue);
    }
    CFRelease(phonesRef);
    
    //Get the emails
    ABMultiValueRef emailsRef = ABRecordCopyValue(person, kABPersonEmailProperty);
    for (int i=0; i<ABMultiValueGetCount(emailsRef); i++) {
        CFStringRef currentEmailLabel = ABMultiValueCopyLabelAtIndex(emailsRef, i);
        CFStringRef currentEmailValue = ABMultiValueCopyValueAtIndex(emailsRef, i);
        
        if (CFStringCompare(currentEmailLabel, kABHomeLabel, 0) == kCFCompareEqualTo) {
            [contactInfoDict setObject:(__bridge NSString *)currentEmailValue forKey:@"homeEmail"];
        }
        
        if (CFStringCompare(currentEmailLabel, kABWorkLabel, 0) == kCFCompareEqualTo) {
            [contactInfoDict setObject:(__bridge NSString *)currentEmailValue forKey:@"workEmail"];
        }
        
        CFRelease(currentEmailLabel);
        CFRelease(currentEmailValue);
    }
    CFRelease(emailsRef);
    
    //Get their contac Img
    if (ABPersonHasImageData(person)) {
        NSData *contactImageData = (__bridge NSData *)ABPersonCopyImageDataWithFormat(person, kABPersonImageFormatThumbnail);
        
        [contactInfoDict setObject:contactImageData forKey:@"image"];
    }
    
    if (_LocalContacts == nil) {
        _LocalContacts = [[NSMutableArray alloc] init];
    }
    [_LocalContacts addObject:contactInfoDict];
    
    [self.tableView reloadData];
    
    [_addressBookController dismissViewControllerAnimated:YES completion:nil];
    
    return NO;
}

-(void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker{
    [_addressBookController dismissViewControllerAnimated:YES completion:nil];
}

-(BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier{
    return NO;
}

#pragma mark Address Book Access
// Check the authorization status of our application for Address Book
-(void)checkAddressBookAccess
{
    switch (ABAddressBookGetAuthorizationStatus())
    {
            // Update our UI if the user has granted access to their Contacts
        case  kABAuthorizationStatusAuthorized:
            [self accessGrantedForAddressBook];
            break;
            // Prompt the user for access to Contacts if there is no definitive answer
        case  kABAuthorizationStatusNotDetermined :
            [self requestAddressBookAccess];
            break;
            // Display a message if the user has denied or restricted access to Contacts
        case  kABAuthorizationStatusDenied:
        case  kABAuthorizationStatusRestricted:
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Privacy Warning"
                                                            message:@"Permission was not granted for Contacts."
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        }
            break;
        default:
            break;
    }
}

// Prompt the user for access to their Address Book data
-(void)requestAddressBookAccess
{
    JCContactsTableViewController * __weak weakSelf = self;
    
    ABAddressBookRequestAccessWithCompletion(self.addressBook, ^(bool granted, CFErrorRef error)
                                             {
                                                 if (granted)
                                                 {
                                                     dispatch_async(dispatch_get_main_queue(), ^{
                                                         [weakSelf accessGrantedForAddressBook];
                                                         
                                                     });
                                                 }
                                             });
}

// This method is called when the user has granted access to their address book data.
-(void)accessGrantedForAddressBook
{
    // Load data from the plist file
//    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"Menu" ofType:@"plist"];
//    self.menuArray = [NSMutableArray arrayWithContentsOfFile:plistPath];
    [self.tableView reloadData];
}


-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UIViewController *viewController = segue.destinationViewController;
    if ([viewController isKindOfClass:[JCCallerViewController class]]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        id object = [self objectAtIndexPath:indexPath];
        if ([object isKindOfClass:[Lines class]]) {
            Lines *line = (Lines *)object;
            JCCallerViewController *callerViewController = (JCCallerViewController *)viewController;
            callerViewController.delegate = self;
            callerViewController.dialString = line.externsionNumber;
        }
    }
}

-(void)shouldDismissCallerViewController:(JCCallerViewController *)viewController
{
    [self dismissViewControllerAnimated:NO completion:^{
        
    }];
}

- (void)configureCell:(UITableViewCell *)cell withObject:(id<NSObject>)object
{
    
    if ([object isKindOfClass:[Lines class]] && [cell isKindOfClass:[JCPersonCell class]]) {
        ((JCPersonCell *)cell).line = (Lines *)object;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForObject:(id<NSObject>)object atIndexPath:(NSIndexPath *)indexPath
{
    if ([object isKindOfClass:[Lines class]]) {
        JCPersonCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PersonCell"];
        [self configureCell:cell withObject:object];
        return cell;
    }
    return nil;
}

#pragma mark - Setters -

-(void)setFilterType:(JCContactFilter)filterType
{
    _filterType = filterType;
    self.predicate = nil;
}

-(void)setPredicate:(NSPredicate *)predicate
{
    if (!predicate) {
        
        if (_searchText && ![_searchText isEqualToString:@""]) {
            predicate = [NSPredicate predicateWithFormat:@"(displayName contains[cd] %@) OR (externsionNumber contains[cd] %@)", _searchText, _searchText];
        }
        
        NSPredicate *filterPredicate = [self predicateFromFilterType];
        if (filterPredicate && predicate)
            predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate, filterPredicate]];
        else if(filterPredicate)
            predicate = filterPredicate;
    }
        
    if (_fetchedResultsController)
    {
        _fetchedResultsController.fetchRequest.predicate = predicate;
        __autoreleasing NSError *error = nil;
        if ([self.fetchedResultsController performFetch:&error])
        {
            [self.tableView reloadData];
        }
    }
}

#pragma mark - Getters -

- (NSFetchedResultsController *)fetchedResultsController
{
    if (!_fetchedResultsController)
    {
        NSFetchRequest *fetchRequest = [Lines MR_requestAllWithPredicate:self.predicate inContext:self.managedObjectContext];
        fetchRequest.fetchBatchSize = 10;
        fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"displayName" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)]];
        super.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:@"firstLetter" cacheName:nil];
    }
    return _fetchedResultsController;
}

- (NSPredicate *)predicate
{
    if (_fetchedResultsController)
        return _fetchedResultsController.fetchRequest.predicate;
    return [self predicateFromFilterType];
}

#pragma mark - Private -

-(NSPredicate *)predicateFromFilterType
{
    if (_filterType == JCContactFilterFavorites) {
        return [NSPredicate predicateWithFormat:@"isFavorite == 1"];
    }
    else if (_filterType == JCContactFilterLocalContacts){
        [self showAddressBook];
    }
    return nil;
}

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

#pragma mark - Delegate handlers -

#pragma mark - Table view data source

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    return [self.fetchedResultsController sectionIndexTitles];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [self.fetchedResultsController sectionIndexTitles][section];
}

#pragma mark - Search Bar Delegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    _searchText = searchText;
    self.predicate = nil;
}

-(void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    [searchBar setShowsCancelButton:YES animated:YES];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
    [searchBar setShowsCancelButton:NO animated:YES];
    searchBar.text = nil;
    _searchText = nil;
    self.predicate = nil;
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
    if (searchBar.text == nil)
        self.predicate = nil;
}

- (NSMutableDictionary *)lineSubscription
{
    if (!lineSubcription) {
        lineSubcription = [[NSUserDefaults standardUserDefaults] objectForKey:@"lineSub"];
        if (!lineSubcription) {
            lineSubcription = [NSMutableDictionary new];
        }
    }
    
    return lineSubcription;
}

#pragma mark - Socket Events
- (void)subscribeToLinePresence:(NSNotification *)notification
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for (Lines *line in [self.fetchedResultsController fetchedObjects]) {
            
            if (self.lineSubscription[line.jrn] && [self.lineSubscription[line.jrn] boolValue]) {
                continue;
            }
            
            [[JasmineSocket sharedInstance] postSubscriptionsToSocketWithId:line.jrn entity:line.jrn type:@"dialog"];
            [self.lineSubscription setObject:@YES forKey:line.jrn];
        }
    });
}

@end
