//
//  JCContactsTableViewController.m
//  JiveOne
//
//  Created by Eduardo  Gueiros on 10/30/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCContactsTableViewController.h"
#import "JCCallerViewController.h"

#import "JCContactCell.h"
#import "JCLineCell.h"
#import "JCExternalContactCell.h"

#import "JasmineSocket.h"

#import "Contact.h"
#import "Line.h"
#import "PBX.h"
#import "User.h"

@interface JCContactsTableViewController()  <JCCallerViewControllerDelegate>
{
    NSString *_searchText;
    NSMutableDictionary *lineSubcription;
}

@property (nonatomic, strong) NSFetchRequest *fetchRequest;
@property (nonatomic, strong) NSPredicate *predicate;

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
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UIViewController *viewController = segue.destinationViewController;
    if ([viewController isKindOfClass:[JCCallerViewController class]]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        id object = [self objectAtIndexPath:indexPath];
        if ([object isKindOfClass:[Contact class]]) {
            Contact *contact = (Contact *)object;
            JCCallerViewController *callerViewController = (JCCallerViewController *)viewController;
            callerViewController.delegate = self;
            callerViewController.dialString = contact.extension;
        }
    }
}



- (void)configureCell:(UITableViewCell *)cell withObject:(id<NSObject>)object
{
    if ([object isKindOfClass:[Contact class]] && [cell isKindOfClass:[JCContactCell class]]) {
        ((JCContactCell *)cell).contact = (Contact *)object;
    }
    else if ([object isKindOfClass:[Line class]] && [cell isKindOfClass:[JCLineCell class]]) {
        ((JCLineCell *)cell).line = (Line *)object;
    }
//    else if ([object isKindOfClass:[UITableViewCell class]] && [cell isKindOfClass:[JCExternalContactCell class]]) {
//        ((JCExternalContactCell *)cell).externalNameLabel = (JCExternalContactCell *)object;
//    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForObject:(id<NSObject>)object atIndexPath:(NSIndexPath *)indexPath
{
    if ([object isKindOfClass:[Contact class]]) {
        JCContactCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ContactCell"];
        [self configureCell:cell withObject:object];
        return cell;
    }
    else if ([object isKindOfClass:[Line class]]) {
        JCLineCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LineCell"];
        [self configureCell:cell withObject:object];
        return cell;
    }
//    else if ([object isKindOfClass:[UITableViewCell class]]) {
//        JCExternalContactCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ExternalContactCell"];
//        [self configureCell:cell withObject:object];
//        return cell;
//    }
    return nil;
}

#pragma mark - Setters -

-(void)setFilterType:(JCContactFilter)filterType
{
    _filterType = filterType;
    [self reloadTable];
}

#pragma mark - Getters -

- (NSFetchedResultsController *)fetchedResultsController
{
    if (!_fetchedResultsController)
    {
        super.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:self.fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:@"firstLetter" cacheName:nil];
    }
    return _fetchedResultsController;
}

- (NSFetchRequest *)fetchRequest
{
    if (!_fetchRequest) {
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"pbxId = %@", [JCAuthenticationManager sharedInstance].line.pbx.pbxId];
        if (_searchText && ![_searchText isEqualToString:@""]) {
            NSPredicate *searchPredicate = [NSPredicate predicateWithFormat:@"(name contains[cd] %@) OR (extension contains[cd] %@)", _searchText, _searchText];
            predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate, searchPredicate]];
        }
        
        if (_filterType == JCContactFilterFavorites) {
            NSPredicate *favoritePredicate =[NSPredicate predicateWithFormat:@"favorite == 1"];
            if (predicate) {
                predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate, favoritePredicate]];
            }
            else {
                predicate = favoritePredicate;
            }
            _fetchRequest = [Contact MR_requestAllWithPredicate:predicate inContext:self.managedObjectContext];
        }
        else {
            _fetchRequest = [Person MR_requestAllWithPredicate:predicate inContext:self.managedObjectContext];
            _fetchRequest.includesSubentities = TRUE;
        }
        _fetchRequest.resultType = NSManagedObjectResultType;
        _fetchRequest.fetchBatchSize = 10;
        _fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)]];
    }
    return _fetchRequest;
}

#pragma mark - Private -

-(void)reloadTable
{
    _fetchedResultsController = nil;
    _fetchRequest = nil;
    [self.tableView reloadData];
}

//-(void)showAddressBook{
//    return;
//}

#pragma mark - Delegate handlers -

-(void)shouldDismissCallerViewController:(JCCallerViewController *)viewController
{
    [self dismissViewControllerAnimated:NO completion:NULL];
}

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
    [self reloadTable];
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
    [self reloadTable];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
    if (searchBar.text == nil)
    {
        [self reloadTable];
    }
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
        for (Line *line in [self.fetchedResultsController fetchedObjects]) {
            
            if (self.lineSubscription[line.jrn] && [self.lineSubscription[line.jrn] boolValue]) {
                continue;
            }
            
            [[JasmineSocket sharedInstance] postSubscriptionsToSocketWithId:line.jrn entity:line.jrn type:@"dialog"];
            [self.lineSubscription setObject:@YES forKey:line.jrn];
        }
    });
}


@end
