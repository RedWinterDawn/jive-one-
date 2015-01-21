//
//  JCContactsTableViewController.m
//  JiveOne
//
//  Created by Eduardo  Gueiros on 10/30/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCContactsTableViewController.h"

#import "JCContactCell.h"
#import "JCLineCell.h"

#import "Contact.h"
#import "Line.h"
#import "PBX.h"
#import "User.h"

#import "JCPhoneManager.h"

@interface JCContactsTableViewController()
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
    
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(lineChanged:) name:kJCAuthenticationManagerLineChangedNotification object:[JCAuthenticationManager sharedInstance]];
}

- (void)configureCell:(UITableViewCell *)cell withObject:(id<NSObject>)object
{
    if ([object isKindOfClass:[Contact class]] && [cell isKindOfClass:[JCContactCell class]]) {
        ((JCContactCell *)cell).contact = (Contact *)object;
    }
    else if ([object isKindOfClass:[Line class]] && [cell isKindOfClass:[JCLineCell class]]) {
        ((JCLineCell *)cell).line = (Line *)object;
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

#pragma mark - Notification handlers -

#pragma mark JCAuthenticationManager

-(void)lineChanged:(NSNotification *)notification
{
    [self reloadTable];
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id object = [self objectAtIndexPath:indexPath];
    if ([object isKindOfClass:[Contact class]]) {
        Contact *contact = (Contact *)object;
        [self dialNumber:contact.extension sender:tableView];
    }
    else if ([object isKindOfClass:[Line class]] && object != [JCAuthenticationManager sharedInstance].line) {
        Line *line = (Line *)object;
        [self dialNumber:line.extension sender:tableView];
    }
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

@end
