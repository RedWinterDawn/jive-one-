//
//  JCFetchedResultsTableViewController.h
//  JiveOne
//
//  Created by Robert Barclay on 10/22/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JCFetchedResultsTableViewController : UITableViewController <NSFetchedResultsControllerDelegate>
{
    NSFetchedResultsController *_fetchedResultsController;
}

@property (nonatomic) BOOL showTopCellSeperator;

// The managed object context being used by the FetchedResults Controller
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

// The Fetched results controller. If set, its sets the managed object context to be its context and reloads the table
// view, performing a fetch. IF not set, an implementing subclass can override the getter to lazy load the fetched
// results controller.
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

// Enables the edit button on the upper left right if nav controller is present. If set to false, sets the right bar
// button item to nil;
@property (nonatomic) BOOL editable;

// Convenience Method for building a fetched results view controller setup for this view controller.
- (NSFetchedResultsController *)fetchedResultsControllerWithEntityName:(NSString *)entityName
                                                             batchSize:(NSInteger)batchSize
                                                             predicate:(NSPredicate *)predicate
                                                       sortDescriptors:(NSArray *)sortDescriptors
                                                     propertiesToFetch:(NSArray *)propertiesToFetch
                                                               section:(NSString *)sectionNameKeyPath
                                                             cacheName:(NSString *)cacheName
                                                                 error:(NSError **)error;

// Method called by the table view data source delegate methods for getting the Table view cell. By default retrives the
// a cell by the identifier "Cell" and calls configure on it. Override for custom behavior.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForObject:(id <NSObject>)object atIndexPath:(NSIndexPath*)indexPath;

// Count of the total objects in the response
@property (nonatomic, readonly) NSUInteger count;

// Number of sections.
@property (nonatomic, readonly) NSUInteger numberOfSections;

- (NSInteger)numberOfRowsInSection:(NSUInteger)section;

// Provide an abstacted means to obtain object from the index path. Meant to be subclassed for customized behavior. Is
// called by configure cell and index path and the returned object is sent on the the configure cell with object. In
// this default case it uses the fetched results controller to determine what object is returned.
- (id<NSObject>)objectAtIndexPath:(NSIndexPath *)indexPath;

// Called when the cell need to be configure for the passed object. By default, it does nothing, and should be overriden
// by an implementing subclass.
- (void)configureCell:(UITableViewCell *)cell withObject:(id<NSObject>)object;

// Receives the passed cell to be configure at the passed index path. Called when a cell is updated or being drawn.
// Default implementation retrives the object from the fetched results controller and calls the method
// [self configureCell:withObject:], to be configured by a subclass. Override for custom index based configuration.
- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;

// Deletes an object at the given index path. Looks up object in the fetched results controller and calls
// [self deleteObject:] with the object. Override for custom behavior. Called from when row is deleted when in edit mode.
- (void)deleteObjectAtIndexPath:(NSIndexPath *)indexPath;

// Deletes the passed object from the managed object context if it is set. Override for custom behavior.
- (void)deleteObject:(id<NSObject>)object;

@end
