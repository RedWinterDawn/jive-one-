//
//  JCStaticTableData.h
//  JiveOne
//
//  Created by Robert Barclay on 6/9/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

@import Foundation;

#import "JCStaticRowData.h"
#import "JCStaticSectionInfo.h"

@protocol JCStaticTableDataDelegate;

@interface JCStaticTableData : NSObject

-(instancetype)initWithTableView:(UITableView *)tableView delegate:(id<JCStaticTableDataDelegate>)delegate;

@property (nonatomic, readonly) id<JCStaticTableDataDelegate> delegate;
@property (nonatomic, readonly) NSArray *sections;
@property (nonatomic, readonly) NSArray *cells;

// use for batch updates
- (void)beginUpdates;
- (void)endUpdates;

// set cell states
- (void)setCell:(UITableViewCell *)cell hidden:(BOOL)hidden;
- (void)setCells:(NSArray *)cells hidden:(BOOL)hidden;

- (void)addCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
- (void)removeCell:(UITableViewCell *)cell;

- (BOOL)cellIsHidden:(UITableViewCell *)cell;
- (NSIndexPath *)indexPathForCell:(UITableViewCell *)cell;

// Display
- (NSInteger)numberOfRowsInSection:(NSInteger)section;
- (UITableViewCell *)cellForRowAtIndexPath:(NSIndexPath *)indexPath;
- (NSIndexPath *)indexPathForVisibleIndexPath:(NSIndexPath *)indexPath;
- (CGFloat)heightForRowAtIndexPath:(NSIndexPath *)indexPath;

@end

@protocol JCStaticTableDataDelegate <NSFetchedResultsControllerDelegate>

typedef NS_ENUM(NSUInteger, JCStaticTableDataChangeType) {
    JCStaticTableDataInsert = 1,
    JCStaticTableDataDelete = 2,
    JCStaticTableDataMove = 3,
    JCStaticTableDataUpdate = 4
};

/* Notifies the delegate that a fetched object has been changed due to an add, remove, move, or update. Enables NSFetchedResultsController change tracking.
	controller - controller instance that noticed the change on its fetched objects
	anObject - changed object
	indexPath - indexPath of changed object (nil for inserts)
	type - indicates if the change was an insert, delete, move, or update
	newIndexPath - the destination path for inserted or moved objects, nil otherwise
	
	Changes are reported with the following heuristics:
 
	On Adds and Removes, only the Added/Removed object is reported. It's assumed that all objects that come after the affected object are also moved, but these moves are not reported.
	The Move object is reported when the changed attribute on the object is one of the sort descriptors used in the fetch request.  An update of the object is assumed in this case, but no separate update message is sent to the delegate.
	The Update object is reported when an object's state changes, and the changed attributes aren't part of the sort keys.
 */
- (void)tableData:(JCStaticTableData *)tableData
    didChangeCell:(UITableViewCell *)cell
      atIndexPath:(NSIndexPath *)indexPath
    forChangeType:(JCStaticTableDataChangeType)type
     newIndexPath:(NSIndexPath *)newIndexPath;

/* Notifies the delegate of added or removed sections.  Enables NSFetchedResultsController change tracking.
 
	controller - controller instance that noticed the change on its sections
	sectionInfo - changed section
	index - index of changed section
	type - indicates if the change was an insert or delete
 
	Changes on section info are reported before changes on fetchedObjects.
 */
- (void)tableData:(JCStaticTableData *)tableData
 didChangeSection:(JCStaticSectionInfo *)sectionInfo
          atIndex:(NSUInteger)sectionIndex
    forChangeType:(JCStaticTableDataChangeType)type;

/* Notifies the delegate that section and object changes are about to be processed and notifications will be sent.  Enables NSFetchedResultsController change tracking.
 Clients utilizing a UITableView may prepare for a batch of updates by responding to this method with -beginUpdates
 */
- (void)tableDataWillChangeContent:(JCStaticTableData *)tableData;

/* Notifies the delegate that all section and object changes have been sent. Enables NSFetchedResultsController change tracking.
 Providing an empty implementation will enable change tracking if you do not care about the individual callbacks.
 */
- (void)tableDataDidChangeContent:(JCStaticTableData *)tableData;

@end