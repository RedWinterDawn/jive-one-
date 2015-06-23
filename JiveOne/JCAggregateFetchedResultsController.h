//
//  JCAggregateFetchedResultsController.h
//  JiveOne
//
//  Created by Robert Barclay on 6/23/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

@import Foundation;

@interface JCAggregateFetchedResultsController : NSFetchedResultsController <NSFetchedResultsControllerDelegate>

-(instancetype)initWithSearchText:(NSString *)searchText
                  sortDescriptors:(NSArray *)sortDescriptors
               sectionNameKeyPath:(NSString *)sectionNameKeyPath
             managedObjectContext:(NSManagedObjectContext *)context;

@property (nonatomic, readwrite, copy) NSArray *fetchedObjects;
@property (nonatomic, readonly) NSString *searchText;

- (id <NSObject> )objectAtIndexPath:(NSIndexPath *)indexPath;
- (NSIndexPath *)indexPathForObject:(id<NSObject>)object;

- (void)addObjectsToSections:(NSArray *)objects;

@end
