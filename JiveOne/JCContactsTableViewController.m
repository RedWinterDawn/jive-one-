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
{
//    UISearchDisplayController *searchDisplayController;
}


@property (nonatomic, strong) NSFetchedResultsController *searchFetchedResultController;





@end

@implementation JCContactsTableViewController

static NSString *CellIdentifier = @"DirectoryCell";

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.tableView registerNib:[UINib nibWithNibName:@"JCPersonCell" bundle:nil] forCellReuseIdentifier:CellIdentifier];
    self.tableView.contentOffset = CGPointMake(0, self.searchDisplayController.searchBar.frame.size.height);
    
    NSError *error;
    if (![self.fetchedResultsController performFetch:&error])
    {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (NSFetchedResultsController *)fetchedResultsController
{
    if (!_fetchedResultsController)
    {
        _fetchedResultsController = [self newFetchedResultsControllerWithSearch:nil];
    }
    
    return _fetchedResultsController;
}

- (NSFetchedResultsController *)searchFetchedResultController
{
    if (!(_searchFetchedResultController)) {
        _searchFetchedResultController = [self newFetchedResultsControllerWithSearch:self.searchDisplayController.searchBar.text];
    }
    return _searchFetchedResultController;
}

- (NSFetchedResultsController *)controllerForTableView:(UITableView *)tableView
{
    return tableView == self.tableView ? self.fetchedResultsController : self.searchFetchedResultController;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    NSInteger count = [[[self controllerForTableView:tableView] sections] count];
    return count;
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    id <NSFetchedResultsSectionInfo> sectionInfo = [[[self controllerForTableView:tableView] sections] objectAtIndex:section];
    
    NSInteger count = [sectionInfo numberOfObjects];
    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];   
    [self configureCell:cell atIndexPath:indexPath forTableView:tableView];
    return cell;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    return [[self controllerForTableView:tableView] sectionIndexTitles];
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [[self controllerForTableView:tableView] sectionIndexTitles][section];
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath forTableView:(UITableView *)tableView
{
    //[self configureCell:cell atIndexPath:indexPath];
    
    NSString *tbv;
    if (tableView == self.tableView) {
        tbv = @"Main TableView";
    }
    else {
        tbv = @"Search TableView";
    }
    
    NSLog(@"Configuring Cell For TableView: %@ at indexPath section: %i, row: %i", tbv, indexPath.section, indexPath.row);
    
    NSFetchedResultsController *controller = [self controllerForTableView:tableView];
    ((JCPersonCell *)cell).line = [controller objectAtIndexPath:indexPath];
    
}

- (NSArray *)reorderHeaders:(NSArray *)headers
{
    NSMutableArray *sectionTitles = [NSMutableArray arrayWithArray:headers];
    
    if ([sectionTitles containsObject:@"\u2605"]) {
        NSInteger index = [sectionTitles indexOfObject:@"\u2605"];
        [sectionTitles removeObjectAtIndex:index];
        [sectionTitles insertObject:@"\u2605" atIndex:0];
    }
    
    return sectionTitles;
}

#pragma mark - Search Delegates
- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope
{
    _searchFetchedResultController.delegate = nil;
    _searchFetchedResultController = nil;
}


#pragma mark - Search Bar
- (void)searchDisplayController:(UISearchDisplayController *)controller willUnloadSearchResultsTableView:(UITableView *)tableView;
{
    // search is done so get rid of the search FRC and reclaim memory
    _searchFetchedResultController.delegate = nil;
    _searchFetchedResultController = nil;
}


- (BOOL)searchDisplayController:(UISearchDisplayController *)controller
shouldReloadTableForSearchString:(NSString *)searchString
{
    [self filterContentForSearchText:searchString
                               scope:[[self.searchDisplayController.searchBar scopeButtonTitles]
                                      objectAtIndex:[self.searchDisplayController.searchBar
                                                     selectedScopeButtonIndex]]];
    
    
    return YES;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption
{
    [self filterContentForSearchText:[self.searchDisplayController.searchBar text]
                               scope:[[self.searchDisplayController.searchBar scopeButtonTitles]
                                      objectAtIndex:[self.searchDisplayController.searchBar
                                                     selectedScopeButtonIndex]]];
    return YES;
}



- (void)changeContactType:(JCContactFilter)type
{    
    
    switch (type) {
        case JCContactFilterFavorites: {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isFavorite == 1"];
            [self.fetchedResultsController.fetchRequest setPredicate:predicate];
            break;
        }
            
        default: {
            self.fetchedResultsController.fetchRequest.predicate = nil;            
            break;
        }
    }
    
    NSError *error;
    if (![self.fetchedResultsController performFetch:&error])
    {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    }
    
    [self.tableView reloadData];
}

//#pragma mark - Overiding NSFetchedResultsDelegate
//- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
//{
//    UITableView *tableView = controller == self.fetchedResultsController ? self.tableView : self.searchDisplayController.searchResultsTableView;
//    [tableView beginUpdates];
//}
//
//
//- (void)controller:(NSFetchedResultsController *)controller
//  didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
//           atIndex:(NSUInteger)sectionIndex
//     forChangeType:(NSFetchedResultsChangeType)type
//{
//    UITableView *tableView = controller == self.fetchedResultsController ? self.tableView : self.searchDisplayController.searchResultsTableView;
//    
//    switch(type)
//    {
//        case NSFetchedResultsChangeInsert:
//            [tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
//            break;
//            
//        case NSFetchedResultsChangeDelete:
//            [tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
//            break;
//    }
//}
//
//
//- (void)controller:(NSFetchedResultsController *)controller
//   didChangeObject:(id)anObject
//       atIndexPath:(NSIndexPath *)theIndexPath
//     forChangeType:(NSFetchedResultsChangeType)type
//      newIndexPath:(NSIndexPath *)newIndexPath
//{
//    UITableView *tableView = controller == self.fetchedResultsController ? self.tableView : self.searchDisplayController.searchResultsTableView;
//    
//    switch(type)
//    {
//        case NSFetchedResultsChangeInsert:
//            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
//            break;
//            
//        case NSFetchedResultsChangeDelete:
//            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:theIndexPath] withRowAnimation:UITableViewRowAnimationFade];
//            break;
//            
//        case NSFetchedResultsChangeUpdate:
//            [self configureCell:[tableView cellForRowAtIndexPath:theIndexPath] atIndexPath:theIndexPath forTableView:tableView];
//            break;
//            
//        case NSFetchedResultsChangeMove:
//            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:theIndexPath] withRowAnimation:UITableViewRowAnimationFade];
//            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]withRowAnimation:UITableViewRowAnimationFade];
//            break;
//    }
//}
//
//
//- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
//{
//    UITableView *tableView = controller == self.fetchedResultsController ? self.tableView : self.searchDisplayController.searchResultsTableView;
//    [tableView endUpdates];
//}
//
//// Override to support renaming section names.
//- (NSString *)controller:(NSFetchedResultsController *)controller sectionIndexTitleForSectionName:(NSString *)sectionName
//{
//    return sectionName;
//}

#pragma mark - Rebuild FetchedController
- (NSFetchedResultsController *)newFetchedResultsControllerWithSearch:(NSString *)searchString
{
    NSFetchRequest *fetchRequest = [Lines MR_requestAll];
    fetchRequest.fetchBatchSize = 10;
    
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"displayName" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
    //NSSortDescriptor *favSort = [NSSortDescriptor sortDescriptorWithKey:@"isFavorite" ascending:NO];
    fetchRequest.sortDescriptors = [NSArray arrayWithObjects:sort , nil];
    
    
    if (searchString.length)
    {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(displayName contains[cd] %@) OR (externsionNumber contains[cd] %@)", searchString, searchString];;
        fetchRequest.predicate = predicate;
    }
    
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                                                managedObjectContext:[NSManagedObjectContext MR_contextForCurrentThread]                                                                                                  sectionNameKeyPath:@"firstLetter"
                                                                                                           cacheName:nil];
    aFetchedResultsController.delegate = self;
    
    NSError *error = nil;
    if (![aFetchedResultsController performFetch:&error])
    {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    }
    
    return aFetchedResultsController;
}




@end
