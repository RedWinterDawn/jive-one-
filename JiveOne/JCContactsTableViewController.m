//
//  JCContactsTableViewController.m
//  JiveOne
//
//  Created by Eduardo  Gueiros on 10/30/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCContactsTableViewController.h"

// Models
#import "InternalExtensionGroup.h"
#import "Extension.h"
#import "Line.h"
#import "Contact.h"
#import "PBX.h"
#import "User.h"

#import "Contact+V5Client.h"
#import "InternalExtension+V5Client.h"

#import "JCAddressBookPerson.h"

// Views
#import "JCPresenceCell.h"

// Controllers
#import "JCContactDetailViewController.h"
#import "JCContactsFetchedResultsController.h"
#import "JCGroupsFetchedResultsController.h"

@interface JCContactsTableViewController()
{
    NSString *_searchText;
}

@end

@implementation JCContactsTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(lineChanged:) name:kJCAuthenticationManagerLineChangedNotification object:self.authenticationManager];
    self.clearsSelectionOnViewWillAppear = TRUE;
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
        detailViewController.managedObjectContext = context;
        if ([sender isKindOfClass:[UITableViewCell class]])
        {
            UITableViewCell *cell = (UITableViewCell *)sender;
            NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
            id object = [self objectAtIndexPath:indexPath];
            if ([object isKindOfClass:[NSManagedObject class]]) {
                NSManagedObject *managedObject = (NSManagedObject *)[self objectAtIndexPath:indexPath];
                id object = [context existingObjectWithID:managedObject.objectID error:nil];
                if ([object conformsToProtocol:@protocol(JCPhoneNumberDataSource)]){
                    detailViewController.phoneNumber = (id<JCPhoneNumberDataSource>)object;
                }
            } else if ([object conformsToProtocol:@protocol(JCPhoneNumberDataSource)]){
                detailViewController.phoneNumber = (id<JCPhoneNumberDataSource>)object;
            }
        }
    }
}

- (void)configureCell:(UITableViewCell *)cell withObject:(id<NSObject>)object
{
    if ([object conformsToProtocol:@protocol(JCPhoneNumberDataSource)]) {
        id <JCPhoneNumberDataSource> phoneNumber = (id<JCPhoneNumberDataSource>)object;
        cell.textLabel.text = phoneNumber.titleText;
        cell.detailTextLabel.text = phoneNumber.detailText;
        
        if ([phoneNumber isKindOfClass:[Extension class]] && [cell isKindOfClass:[JCPresenceCell class]]) {
            ((JCPresenceCell *)cell).identifier = ((Extension *)phoneNumber).jrn;
        }
    }
    else if ([object isKindOfClass:[InternalExtensionGroup class]]) {
        cell.textLabel.text = ((InternalExtensionGroup *)object).name;
    }
}

-(IBAction)sync:(id)sender
{
    if ([sender isKindOfClass:[UIRefreshControl class]]) {
        Line *line = self.authenticationManager.line;
//        [InternalExtension downloadInternalExtensionsForLine:line complete:^(BOOL success, NSError *error) {
//            
//        }];
        
        User *user = line.pbx.user;
        [Contact syncContactsForUser:user completion:^(BOOL success, NSError *error) {
            [((UIRefreshControl *)sender) endRefreshing];
            if (error) {
                [self showError:error];
            }
        }];
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
        NSArray *sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)]];
        PBX *pbx = self.authenticationManager.pbx;
        switch (_filterType) {
            case JCContactFilterGrouped:
            {
                _fetchedResultsController = [[JCGroupsFetchedResultsController alloc] initWithSearchText:_searchText
                                                                                         sortDescriptors:sortDescriptors
                                                                                                     pbx:pbx
                                                                                      sectionNameKeyPath:@"sectionName"];
                
                break;
            }
                
            default:
            {
                _fetchedResultsController = [[JCContactsFetchedResultsController alloc] initWithSearchText:_searchText
                                                                                           sortDescriptors:sortDescriptors
                                                                                                       pbx:pbx
                                                                                        sectionNameKeyPath:@"firstInitial"];
                break;
            }
        }
        
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
    [self.tableView reloadData];
}

#pragma mark - Notification Handlers -

-(void)lineChanged:(NSNotification *)notification
{
    [self reloadTable];
}

#pragma mark - Delegate Handlers -

#pragma mark UITableViewDataSource

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
        id<NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
        return sectionInfo.name;
    }
    return [self.fetchedResultsController sectionIndexTitles][section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForObject:(id<NSObject>)object atIndexPath:(NSIndexPath *)indexPath
{
    if ([object conformsToProtocol:@protocol(JCPhoneNumberDataSource)]) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ContactCell"];
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

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    id<JCPhoneNumberDataSource> phoneNumber = (id<JCPhoneNumberDataSource>)[self objectAtIndexPath:indexPath];
    if ([phoneNumber isKindOfClass:[Extension class]]) {
        return FALSE;
    } else if ([phoneNumber isKindOfClass:[JCAddressBookPerson class]]) {
        return FALSE;
    }
    return TRUE;
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

-(void)deleteObject:(id<NSObject>)object
{
    if ([object isKindOfClass:[Contact class]]) {
        Contact *contact = (Contact *)object;
        [self showStatus:NSLocalizedString(@"Deleting...", @"Deleting a contact")];
        [contact markForDeletion:^(BOOL success, NSError *error) {
            [self hideStatus];
        }];
    } else {
        [super deleteObject:object];
    }
}

#pragma mark UISearchBarDelegate

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
