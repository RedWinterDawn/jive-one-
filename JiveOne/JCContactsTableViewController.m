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
#import "ContactGroup.h"
#import "Extension.h"

#import "JCPhoneManager.h"
#import "JCContactDetailTableViewController.h"

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
    [center addObserver:self selector:@selector(lineChanged:) name:kJCAuthenticationManagerLineChangedNotification object:self.authenticationManager];
}

- (void)configureCell:(UITableViewCell *)cell withObject:(id<NSObject>)object
{
    if ([object isKindOfClass:[Contact class]] && [cell isKindOfClass:[JCContactCell class]]) {
        ((JCContactCell *)cell).contact = (Contact *)object;
    }
    else if ([object isKindOfClass:[Line class]] && [cell isKindOfClass:[JCLineCell class]]) {
        ((JCLineCell *)cell).line = (Line *)object;
    }
    else if ([object isKindOfClass:[ContactGroup class]]) {
        cell.textLabel.text = ((ContactGroup *)object).name;
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
    else if ([object isKindOfClass:[ContactGroup class]])
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
    
    if ([viewController isKindOfClass:[JCContactDetailTableViewController class]]) {
        if ([sender isKindOfClass:[UITableViewCell class]]) {
            UITableViewCell *cell = (UITableViewCell *)sender;
            NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
            JCPersonManagedObject *person = (JCPersonManagedObject *)[self objectAtIndexPath:indexPath];
            JCContactDetailTableViewController *detailViewController = (JCContactDetailTableViewController *)viewController;
            detailViewController.phoneNumber = person;
        }
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
        NSString *sectionKeyPath = @"firstInitial";
        if (_filterType == JCContactFilterGrouped) {
            sectionKeyPath = nil;
        }
        super.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:self.fetchRequest
                                                                             managedObjectContext:self.managedObjectContext
                                                                               sectionNameKeyPath:sectionKeyPath
                                                                                        cacheName:nil];
    }
    return _fetchedResultsController;
}

- (NSFetchRequest *)fetchRequest
{
    if (!_fetchRequest)
    {
        Line *line = self.authenticationManager.line;
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"pbxId = %@", line.pbxId];
        if (_searchText && ![_searchText isEqualToString:@""]) {
            NSPredicate *searchPredicate = [NSPredicate predicateWithFormat:@"(name contains[cd] %@) OR (number contains[cd] %@)", _searchText, _searchText];
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
        else if (_filterType == JCContactFilterGrouped) {
            NSPredicate *predicate =[NSPredicate predicateWithFormat:@"contacts.pbx.jrn CONTAINS[cd] %@", line.pbx.jrn];
            if (_searchText && ![_searchText isEqualToString:@""]) {
                NSPredicate *searchPredicate = [NSPredicate predicateWithFormat:@"name contains[cd] %@", _searchText];
                predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate, searchPredicate]];
            }
            _fetchRequest = [ContactGroup MR_requestAllWithPredicate:predicate inContext:self.managedObjectContext];
        }
        else {
            ContactGroup *contactGroup = self.contactGroup;
            if (contactGroup) {
                NSPredicate *contactGroupPredicate =[NSPredicate predicateWithFormat:@"groups CONTAINS[cd] %@", contactGroup];
                predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate, contactGroupPredicate]];
                _fetchRequest = [Contact MR_requestAllWithPredicate:predicate inContext:self.managedObjectContext];
            } else {
                _fetchRequest = [Extension MR_requestAllWithPredicate:predicate inContext:self.managedObjectContext];
                _fetchRequest.includesSubentities = TRUE;
            }
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
    Line *line = self.authenticationManager.line;
	if ([object isKindOfClass:[ContactGroup class]]) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(contactsTableViewController:didSelectContactGroup:)]) {
            [self.delegate contactsTableViewController:self didSelectContactGroup:(ContactGroup *)object];
        }
    }
    else if ([object conformsToProtocol:@protocol(JCPhoneNumberDataSource)] && object != line) {
        if ( UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad ) {
            [self dialPhoneNumber:(id<JCPhoneNumberDataSource>)object
                        usingLine:line
                           sender:tableView];
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
