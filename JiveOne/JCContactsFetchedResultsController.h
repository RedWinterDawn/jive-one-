//
//  JCContactsFetchedResultsController.h
//  JiveOne
//
//  This objects acts as a wrapper around getting a list of phone numbers from Extensions, Contacts,
//  and the Local Address Book.
//
//  Created by Robert Barclay on 6/5/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

@import Foundation;

#import "JCPhoneNumberDataSource.h"

@protocol JCContactsFetchedResultsController;

@interface JCContactsFetchedResultsController : NSObject

- (instancetype)initWithFetchRequest:(NSFetchRequest *)fetchRequest pbx:(PBX *)pbx sectionNameKeyPath:(NSString *)sectionNameKeyPath;

@property (nonatomic, weak) id <JCContactsFetchedResultsController> delegate;

/* ========================================================*/
/* ====================== CONFIGURATION ===================*/
/* ========================================================*/

@property (nonatomic, readonly) NSFetchRequest *fetchRequest;
@property (nonatomic, readonly) NSManagedObjectContext *managedObjectContext;


/* The keyPath on the fetched objects used to determine the section they belong to. */
@property (nonatomic, readonly) NSString *sectionNameKeyPath;

/* ========================================================*/
/* ============= ACCESSING OBJECT RESULTS =================*/
/* ========================================================*/

/* Returns the results of the fetch.
 Returns nil if the performFetch: hasn't been called.
 */
@property (nonatomic, readonly) NSArray *fetchedObjects;

- (BOOL)performFetch:(NSError **)error;
- (id <JCPhoneNumberDataSource> )objectAtIndexPath:(NSIndexPath *)indexPath;
- (NSIndexPath *)indexPathForObject:(id<JCPhoneNumberDataSource>)object;

/* ========================================================*/
/* =========== CONFIGURING SECTION INFORMATION ============*/
/* ========================================================*/

/* Returns the corresponding section index entry for a given section name.
 Default implementation returns the capitalized first letter of the section name.
 Developers that need different behavior can implement the delegate method -(NSString*)controller:(NSFetchedResultsController *)controller sectionIndexTitleForSectionName
 Only needed if a section index is used.
 */
- (NSString *)sectionIndexTitleForSectionName:(NSString *)sectionName;

/* Returns the array of section index titles.
 It's expected that developers call this method when implementing UITableViewDataSource's
	- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
	
 The default implementation returns the array created by calling sectionIndexTitleForSectionName: on all the known sections.
 Developers should override this method if they wish to return a different array for the section index.
 Only needed if a section index is used.
 */
@property (nonatomic, readonly) NSArray *sectionIndexTitles;

/* ========================================================*/
/* =========== QUERYING SECTION INFORMATION ===============*/
/* ========================================================*/

/* Returns an array of objects that implement the NSFetchedResultsSectionInfo protocol.
 It's expected that developers use the returned array when implementing the following methods of the UITableViewDataSource protocol
 
 - (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView;
 - (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section;
 - (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section;
 
 */
@property (nonatomic, readonly) NSArray *sections;

/* Returns the section number for a given section title and index in the section index.
 It's expected that developers call this method when executing UITableViewDataSource's
	- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index;
 */
- (NSInteger)sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)sectionIndex;


@end

@protocol JCContactsFetchedResultsController <NSFetchedResultsControllerDelegate>

@end

