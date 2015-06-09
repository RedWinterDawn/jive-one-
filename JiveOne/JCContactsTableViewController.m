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
    
    JCContactsFetchedResultsController *_contactsFetchedResultsController;
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

- (JCContactsFetchedResultsController *)fetchedResultsController
{
    if (!_contactsFetchedResultsController)
    {
        PBX *pbx = self.authenticationManager.pbx;
        _contactsFetchedResultsController = [[JCContactsFetchedResultsController alloc] initWithFetchRequest:self.fetchRequest
                                                                                                         pbx:pbx
                                                                                          sectionNameKeyPath:@"firstInitial"];
        
        __autoreleasing NSError *error = nil;
        if ([_contactsFetchedResultsController performFetch:&error])
            [self.tableView reloadData];
    }
    return _contactsFetchedResultsController;
}

- (NSFetchRequest *)fetchRequest
{
    if (!_fetchRequest)
    {
        NSPredicate *predicate;
        if (_searchText && ![_searchText isEqualToString:@""]) {
            predicate = [NSPredicate predicateWithFormat:@"(name contains[cd] %@) OR (number contains[cd] %@)", _searchText, _searchText];
        }
        
//        if (_filterType == JCContactFilterFavorites) {
//            NSPredicate *favoritePredicate =[NSPredicate predicateWithFormat:@"favorite == 1"];
//            if (predicate) {
//                predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate, favoritePredicate]];
//            }
//            else {
//                predicate = favoritePredicate;
//            }
//            _fetchRequest = [InternalExtension MR_requestAllWithPredicate:predicate inContext:self.managedObjectContext];
//        }
//        else if (_filterType == JCContactFilterGrouped) {
//            NSPredicate *predicate =[NSPredicate predicateWithFormat:@"contacts.pbx.jrn CONTAINS[cd] %@", line.pbx.jrn];
//            if (_searchText && ![_searchText isEqualToString:@""]) {
//                NSPredicate *searchPredicate = [NSPredicate predicateWithFormat:@"name contains[cd] %@", _searchText];
//                predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate, searchPredicate]];
//            }
//            _fetchRequest = [InternalExtensionGroup MR_requestAllWithPredicate:predicate inContext:self.managedObjectContext];
//        }
//        else {
//            InternalExtensionGroup *contactGroup = self.contactGroup;
//            if (contactGroup) {
//                NSPredicate *contactGroupPredicate =[NSPredicate predicateWithFormat:@"groups CONTAINS[cd] %@", contactGroup];
//                predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate, contactGroupPredicate]];
//                _fetchRequest = [InternalExtension MR_requestAllWithPredicate:predicate inContext:self.managedObjectContext];
//            } else {
                _fetchRequest = [Extension MR_requestAllWithPredicate:predicate inContext:self.managedObjectContext];
                _fetchRequest.includesSubentities = TRUE;
//            }
//        }
        _fetchRequest.resultType = NSManagedObjectResultType;
        _fetchRequest.fetchBatchSize = 10;
        _fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)]];
    }
    return _fetchRequest;
}



#pragma mark - Private -

-(void)reloadTable
{
    _contactsFetchedResultsController = nil;
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
