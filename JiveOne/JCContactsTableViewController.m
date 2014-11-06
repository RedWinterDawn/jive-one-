//
//  JCContactsTableViewController.m
//  JiveOne
//
//  Created by Eduardo  Gueiros on 10/30/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCContactsTableViewController.h"
#import "Lines+Custom.h"
#import "JCPersonCell.h"



@interface JCContactsTableViewController ()

@property (nonatomic, strong) NSPredicate *predicate;

@end

@implementation JCContactsTableViewController

- (NSFetchedResultsController *)fetchedResultsController
{
    if (!_fetchedResultsController)
    {
        NSFetchRequest *fetchRequest = [Lines MR_requestAllWithPredicate:self.predicate inContext:self.managedObjectContext];
        fetchRequest.fetchBatchSize = 10;
        fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"displayName" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)]];
        
        /**/
        
        super.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:@"firstLetter" cacheName:nil];
    }
    
    return _fetchedResultsController;
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
    NSPredicate *oldPredicate = self.predicate;
    if (oldPredicate != predicate)
    {
        NSPredicate *filterPredicate = [self predicateFromFilterType];
        if (filterPredicate && predicate)
            predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate, filterPredicate]];
        else if(filterPredicate)
            predicate = filterPredicate;
        
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
}

#pragma mark - Getters -

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
    NSPredicate *predicate = nil;
    if (searchText != nil && ![searchText isEqualToString:@""])
        predicate = [NSPredicate predicateWithFormat:@"(displayName contains[cd] %@) OR (externsionNumber contains[cd] %@)", searchText, searchText];
    
    self.predicate = predicate;
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

@end
