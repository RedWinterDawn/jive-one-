//
//  JCFetchedResultsTableViewController.m
//  JiveOne
//
//  Created by Robert Barclay on 10/22/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCFetchedResultsTableViewController.h"
#import <MagicalRecord/MagicalRecord.h>

@interface JCFetchedResultsTableViewController ()
{
    NSManagedObjectContext *_managedObjectContext;
}

@end

@implementation JCFetchedResultsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    self.clearsSelectionOnViewWillAppear = NO;
    if (_editable)
    {
        self.navigationItem.rightBarButtonItem = self.editButtonItem;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    self.fetchedResultsController = nil;
}

#pragma mark - Setters - 

- (void)setManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != managedObjectContext) {
        _managedObjectContext = managedObjectContext;
        self.fetchedResultsController = nil;
        [self.tableView reloadData];
    }
}

-(void)setFetchedResultsController:(NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != fetchedResultsController)
    {
        _fetchedResultsController = fetchedResultsController;
        if (fetchedResultsController.managedObjectContext != _managedObjectContext) {
            self.managedObjectContext = fetchedResultsController.managedObjectContext;
        }
        
        _fetchedResultsController.delegate = self;
        
        // Make sure the _fetched result controller has fetched data and reload
        // the table if sucessfull.
        __autoreleasing NSError *error = nil;
        if ([_fetchedResultsController performFetch:&error])
            [self.tableView reloadData];
    }
}

-(void)setEditable:(BOOL)editable
{
    _editable = editable;
    if (_editable)
        self.navigationItem.rightBarButtonItem = self.editButtonItem;
    else
        self.navigationItem.rightBarButtonItem = nil;
}

#pragma mark - Getters -

- (NSManagedObjectContext *)managedObjectContext
{
    if (!_managedObjectContext)
        _managedObjectContext = [NSManagedObjectContext MR_defaultContext];
    return _managedObjectContext;
}

#pragma mark - Public Methods -

- (NSFetchedResultsController *)fetchedResultsControllerWithEntityName:(NSString *)entityName batchSize:(NSInteger)batchSize predicate:(NSPredicate *)predicate sortDescriptors:(NSArray *)sortDescriptors propertiesToFetch:(NSArray *)propertiesToFetch section:(NSString *)sectionNameKeyPath cacheName:(NSString *)cacheName error:(NSError **)error
{
    if (batchSize <= 4)
        batchSize = 5; // Set a minimum batch size to be 5.
    
    // Build Fetch Request
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:entityName];
    [request setFetchBatchSize:batchSize];
    
    if (predicate)
        [request setPredicate:predicate];
    
    [request setSortDescriptors:sortDescriptors];
    
    if (propertiesToFetch && propertiesToFetch.count > 0)
        [request setPropertiesToFetch:propertiesToFetch];
    
    // Build Fetch Request Controller
    NSFetchedResultsController *fetchResultController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:self.managedObjectContext sectionNameKeyPath:sectionNameKeyPath cacheName:cacheName];
    fetchResultController.delegate = self;
    [fetchResultController performFetch:error];
    return fetchResultController;
}

#pragma mark Methods for Subclassing

-(NSUInteger)count
{
    return self.fetchedResultsController.fetchedObjects.count;
}

-(NSInteger)countAtIndexPath
{
    return 0;
}

-(id <NSObject>)objectForIndexPath:(NSIndexPath *)indexPath
{
    return [self.fetchedResultsController objectAtIndexPath:indexPath];
}

-(void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    [self configureCell:cell withObject:[self objectForIndexPath:indexPath]];
}

-(void)configureCell:(UITableViewCell *)cell withObject:(id<NSObject>)object
{
    // Method to be subclassed. By Default, do nothing.
}

-(void)deleteObjectAtIndexPath:(NSIndexPath *)indexPath
{
    id object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    [self deleteObject:object];
}

-(void)deleteObject:(id<NSObject>)object
{
    if ([object isKindOfClass:[NSManagedObject class]])
    {
        NSManagedObject *managedObject = (NSManagedObject *)object;
        [managedObject.managedObjectContext deleteObject:object];
        
        // Save the context.
        __autoreleasing NSError *error = nil;
        if (![managedObject.managedObjectContext save:&error])
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    }
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForObject:(id <NSObject>)object atIndexPath:(NSIndexPath*)indexPath;
{
    // Method to be subclassed. By Default, returns a default cell with the row
    // number for the title.
    static NSString *defaultTableViewCell = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:defaultTableViewCell];
    [cell setSeparatorInset:UIEdgeInsetsFromString(@"1")];
    [self configureCell:cell withObject:object];
    return cell;
}


#pragma mark - Delegate Handlers -

#pragma mark UITableViewDataSource

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.fetchedResultsController.sections.count;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController.sections objectAtIndex:section];
    if (sectionInfo)
        return [sectionInfo numberOfObjects];
    return 0;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    id object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    UITableViewCell *cell = [self tableView:tableView cellForObject:object atIndexPath:indexPath];
    return cell;
}

#pragma mark UITableViewDelegate

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
        [self deleteObjectAtIndexPath:indexPath];
}

#pragma mark NSFetchedResultsControllerDelegate

-(void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}

-(void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        default:
            break;
    }
}

-(void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    UITableView *tableView = self.tableView;
    switch(type)
    {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationTop];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
        {
            UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            [self configureCell:cell atIndexPath:indexPath];
            break;
        }
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

-(void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    
}

@end
