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

@interface JCContactsTableViewController()  <JCCallerViewControllerDelegate>
{
    NSString *_searchText;
    NSMutableDictionary *lineSubcription;
}

@property (nonatomic, weak) NSPredicate *predicate;

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

-(void)shouldDismissCallerViewController:(JCCallerViewController *)viewController
{
    [self dismissViewControllerAnimated:NO completion:NULL];
}

- (void)configureCell:(UITableViewCell *)cell withObject:(id<NSObject>)object
{
    if ([object isKindOfClass:[Contact class]] && [cell isKindOfClass:[JCContactCell class]]) {
        ((JCContactCell *)cell).contact = (Contact *)object;
    }
    else if ([object isKindOfClass:[Line class]] && [cell isKindOfClass:[JCLineCell class]]) {
        ((JCLineCell *)cell).line = (Line *)object;
    }
    else if ([object isKindOfClass:[UITableViewCell class]] && [cell isKindOfClass:[JCExternalContactCell class]]) {
        ((JCExternalContactCell *)cell).externalNameLabel = (JCExternalContactCell *)object;
    }
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
    else if ([object isKindOfClass:[UITableViewCell class]]) {
        JCExternalContactCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ExternalContactCell"];
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
        NSLog(@"predicate : %@",predicate);
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
        NSFetchRequest *fetchRequest = [Person MR_requestAllWithPredicate:self.predicate inContext:self.managedObjectContext];
        fetchRequest.includesSubentities = TRUE;
        fetchRequest.fetchBatchSize = 10;
        fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)]];
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
