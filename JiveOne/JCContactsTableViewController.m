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

#import "InternalExtension.h"
#import "Line.h"
#import "PBX.h"
#import "User.h"
#import "InternalExtensionGroup.h"
#import "Extension.h"
#import "Contact.h"

#import "JCPhoneManager.h"
#import "JCContactDetailViewController.h"
#import "JCContactsFetchedResultsController.h"

@interface JCContactsTableViewController() <JCContactCellDelegate>
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
    [center addObserver:self selector:@selector(lineChanged:) name:kJCAuthenticationManagerLineChangedNotification object:self.authenticationManager];
}

- (void)configureCell:(UITableViewCell *)cell withObject:(id<NSObject>)object
{
    if ([object conformsToProtocol:@protocol(JCPhoneNumberDataSource)]) {
        id<JCPhoneNumberDataSource> phoneNumber = (id<JCPhoneNumberDataSource>)object;
        cell.textLabel.text = phoneNumber.titleText;
        cell.detailTextLabel.text = phoneNumber.detailText;
        
        // Setup Presence for Internal Extensions.
        if ([phoneNumber isKindOfClass:[Extension class]] && [cell isKindOfClass:[JCPresenceCell class]]) {
            ((JCPresenceCell *)cell).identifier = ((Extension *)phoneNumber).jrn;
        }
        
        // TODO: Favorites;
    }
    else if ([object isKindOfClass:[InternalExtensionGroup class]]) {
        cell.textLabel.text = ((InternalExtensionGroup *)object).name;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForObject:(id<NSObject>)object atIndexPath:(NSIndexPath *)indexPath
{
    if ([object isKindOfClass:[InternalExtension class]]) {
        JCContactCell *cell = [tableView dequeueReusableCellWithIdentifier:@"InternalExtensionCell"];
        cell.delegate = self;
        [self configureCell:cell withObject:object];
        return cell;
    }
    if ([object isKindOfClass:[Contact class]]) {
        JCContactCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ContactCell"];
        cell.delegate = self;
        [self configureCell:cell withObject:object];
        return cell;
    }
    else if ([object isKindOfClass:[Line class]]) {
        JCLineCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LineCell"];
        [self configureCell:cell withObject:object];
        return cell;
    }
    else if ([object isKindOfClass:[InternalExtensionGroup class]])
    {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ContactGroupCell"];
        [self configureCell:cell withObject:object];
        return cell;
    }
    return nil;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UIViewController *viewController = segue.destinationViewController;
    if ([viewController isKindOfClass:[UINavigationController class]]) {
        viewController = ((UINavigationController *)viewController).topViewController;
    }
    
    if ([viewController isKindOfClass:[JCContactDetailViewController class]]) {
        JCContactDetailViewController *detailViewController = (JCContactDetailViewController *)viewController;
        NSManagedObjectContext *context = [NSManagedObjectContext MR_contextWithParent:self.managedObjectContext];
        if ([sender isKindOfClass:[UITableViewCell class]]) {
            UITableViewCell *cell = (UITableViewCell *)sender;
            NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
            NSManagedObject *managedObject = (NSManagedObject *)[self objectAtIndexPath:indexPath];
            id object = [context existingObjectWithID:managedObject.objectID error:nil];
            if ([object conformsToProtocol:@protocol(JCPhoneNumberDataSource)]) {
                detailViewController.phoneNumber = (id<JCPhoneNumberDataSource>)object;
            }
        }
        detailViewController.managedObjectContext = context;
    }
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
        NSPredicate *predicate;
        if (_searchText && ![_searchText isEqualToString:@""]) {
            predicate = [NSPredicate predicateWithFormat:@"(name contains[cd] %@) OR (number contains[cd] %@)", _searchText, _searchText];
        }
        
        NSFetchRequest *fetchRequest = [Contact MR_requestAllWithPredicate:predicate inContext:self.managedObjectContext];
        fetchRequest.includesSubentities = TRUE;
        fetchRequest.resultType = NSManagedObjectResultType;
        fetchRequest.fetchBatchSize = 10;
        fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)]];
        
        
        PBX *pbx = self.authenticationManager.pbx;
        _fetchedResultsController = [[JCContactsFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                                                         pbx:pbx
                                                                                          sectionNameKeyPath:@"firstInitial"];
        _fetchedResultsController.delegate = self;
        
        __autoreleasing NSError *error = nil;
        if ([_fetchedResultsController performFetch:&error])
            [self.tableView reloadData];
    }
    return _fetchedResultsController;
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

- (void)contactCell:(JCContactCell *)cell didMarkAsFavorite:(BOOL)favorite
{
    // TODO: Finish Favorites.
}

#pragma mark - Table view data source

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    if (_filterType == JCContactFilterGrouped) {
        return nil;
    }
    return [self.fetchedResultsController sectionIndexTitles];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (_filterType == JCContactFilterGrouped) {
        return nil;
    }
    return [self.fetchedResultsController sectionIndexTitles][section];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id object = [self objectAtIndexPath:indexPath];
    if ([object isKindOfClass:[InternalExtensionGroup class]]) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(contactsTableViewController:didSelectContactGroup:)]) {
            [self.delegate contactsTableViewController:self didSelectContactGroup:(InternalExtensionGroup *)object];
        }
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
    if (searchBar.text == nil) {
        [self reloadTable];
    }
}

@end
