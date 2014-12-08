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
@import AddressBook;


@interface JCContactsTableViewController()  <JCCallerViewControllerDelegate>
{
    NSString *_searchText;
    NSMutableDictionary *lineSubcription;
}

@property (nonatomic, weak) NSPredicate *predicate;
- (ABAddressBookRef)addressBook;
- (void)setAddressBook:(ABAddressBookRef)newAddressBook;

@end

@implementation JCContactsTableViewController
{
    ABAddressBookRef _addressBook;
}

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
    
    //Request For address book acces TODO: add toggle switch for this also add it to settings
    [self requestAddressBookAccess];
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
    return nil;
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
#pragma mark - Helper methods

- (void)alertViewWithDataClass:(JCContactFilter)class status:(NSString *)status {
    NSString *formatString = NSLocalizedString(@"ACCESS_LEVEL", @"");
    NSString *message = [NSString stringWithFormat:formatString, [self stringForDataClass:class], status];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"REQUEST_STATUS", @"") message:message delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
    [alertView show];
}

- (NSString *)stringForDataClass:(JCContactFilter)class {
    if(class == Contacts) {
        return kDataClassContacts;
    }
    return nil;
}
#pragma mark - UITableViewDelegate methods

- (void)dealloc {
    if(_addressBook) {
        ABAddressBookUnregisterExternalChangeCallback(_addressBook, handleAddressBookChange, (__bridge void *)(self));
        CFRelease(_addressBook);
    }
    
}

#pragma mark - Contacts methods

- (void)checkAddressBookAccess {
    /*
     We can ask the address book ahead of time what the authorization status is for our bundle and take the appropriate action.
     */
    ABAuthorizationStatus status = ABAddressBookGetAuthorizationStatus();
    if(status == kABAuthorizationStatusNotDetermined) {
        [self alertViewWithDataClass:Contacts status:NSLocalizedString(@"UNDETERMINED", @"")];
    }
    else if(status == kABAuthorizationStatusRestricted) {
        [self alertViewWithDataClass:Contacts status:NSLocalizedString(@"RESTRICTED", @"")];
    }
    else if(status == kABAuthorizationStatusDenied) {
        [self alertViewWithDataClass:Contacts status:NSLocalizedString(@"DENIED", @"")];
    }
    else if(status == kABAuthorizationStatusAuthorized) {
        [self alertViewWithDataClass:Contacts status:NSLocalizedString(@"GRANTED", @"")];
    }
}

void handleAddressBookChange(ABAddressBookRef addressBook, CFDictionaryRef info, void *context) {
    /*
     Do something with changed addres book data...
     */
}

- (void)requestAddressBookAccess {
    
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
    
    if(addressBook) {
        self.addressBook = CFAutorelease(addressBook);
        /*
         Register for a callback if the addressbook data changes this is important to be notified of new data when the user grants access to the contacts. the application should also be able to handle a nil object being returned as well if the user denies access to the address book.
         */
        ABAddressBookRegisterExternalChangeCallback(self.addressBook, handleAddressBookChange, (__bridge void *)(self));
        
        /*
         When the application requests to receive address book data that is when the user is presented with a consent dialog.
         */
        ABAddressBookRequestAccessWithCompletion(self.addressBook, ^(bool granted, CFErrorRef error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self alertViewWithDataClass:Contacts status:(granted) ? NSLocalizedString(@"GRANTED", @"") : NSLocalizedString(@"DENIED", @"")];
            });
        });
    }
}


- (ABAddressBookRef)addressBook {
    return _addressBook;
}

- (void)setAddressBook:(ABAddressBookRef)newAddressBook {
    if (_addressBook != newAddressBook) {
        if (_addressBook != NULL) {
            CFRelease(_addressBook);
        }
        if (newAddressBook != NULL) {
            CFRetain(newAddressBook);
        }
        _addressBook = newAddressBook;
    }
}




@end
