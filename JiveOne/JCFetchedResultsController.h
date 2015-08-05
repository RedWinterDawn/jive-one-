//
//  JCFetchedResultsController.h
//  JiveOne
//
//  This class provides an implementation of a fetched results controller where a
//  NSFetchedResultsController would not work, due to limitations of core data. It is built to be
//  able to be subclassed. It handles NSManagedObjectContext content update notification events, and
//  provides a mechanism where The same update processing can be manually triggered.
//
//  Created by Robert Barclay on 7/27/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol JCFetchedResultsControllerDelegate;

@interface JCFetchedResultsController : NSObject {
    NSMutableArray *_fetchedObjects;
}

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)context
                                fetchRequest:(NSFetchRequest *)request;

@property (nonatomic, weak) id <JCFetchedResultsControllerDelegate> delegate;

@property (nonatomic, readonly) NSFetchRequest *fetchRequest;
@property (nonatomic, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readonly) NSArray *fetchedObjects;

- (BOOL)performFetch:(NSError **)error;
- (id<NSObject>)objectAtIndexPath:(NSIndexPath *)indexPath;
- (NSIndexPath *)indexPathForObject:(id<NSObject>)object;

// Methods to be overridden
- (id<NSObject>)objectForObject:(id<NSObject>)object;
- (NSArray *)objectsForObjects:(NSArray *)objects;
- (BOOL)predicateEvaluatesToObject:(id<NSObject>)object;
- (BOOL)checkIfSortingChangedForObject:(id<NSObject>)object;
- (void)updateResultsWithDictionary:(NSDictionary *)userInfo;

@end

@protocol JCFetchedResultsControllerDelegate <NSFetchedResultsControllerDelegate, NSObject>

@optional
- (void)controller:(JCFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath;

- (void)controller:(JCFetchedResultsController *)controller
  didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex
     forChangeType:(NSFetchedResultsChangeType)type;

- (void)controllerWillChangeContent:(JCFetchedResultsController *)controller;

- (void)controllerDidChangeContent:(JCFetchedResultsController *)controller;

@end

