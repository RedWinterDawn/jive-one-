//
//  JCConversationGroups.h
//  JiveOne
//
//  Created by Robert Barclay on 2/23/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

@import Foundation;

@class JCConversationGroupsResultsController;

@protocol JCConversationGroupsResultsControllerDelegate;


@interface JCConversationGroupsResultsController : NSObject

- (id)initWithFetchRequest:(NSFetchRequest *)fetchRequest managedObjectContext: (NSManagedObjectContext *)context;
- (BOOL)performFetch:(NSError **)error;

@property (nonatomic, readonly) NSFetchRequest *fetchRequest;
@property (nonatomic, readonly) NSManagedObjectContext *manageObjectContext;
@property (nonatomic, readonly) NSArray *fetchedObjects;
@property (nonatomic, weak) id <JCConversationGroupsResultsControllerDelegate> delegate;

- (id)objectAtIndexPath:(NSIndexPath *)indexPath;

-(NSIndexPath *)indexPathForObject:(id)object;

@end

@protocol JCConversationGroupsResultsControllerDelegate <NSObject>

typedef NS_ENUM(NSUInteger, JCConversationGroupsResultsChangeType) {
    JCConversationGroupsResultsChangeInsert = NSFetchedResultsChangeInsert,
    JCConversationGroupsResultsChangeDelete = NSFetchedResultsChangeDelete,
    JCConversationGroupsResultsChangeMove = NSFetchedResultsChangeMove,
    JCConversationGroupsResultsChangeUpdate = NSFetchedResultsChangeUpdate
};

@optional
- (void)conversationGroupResultsController:(JCConversationGroupsResultsController *)controller
                           didChangeObject:(id)anObject
                               atIndexPath:(NSIndexPath *)indexPath
                             forChangeType:(JCConversationGroupsResultsChangeType)type
                              newIndexPath:(NSIndexPath *)newIndexPath;

- (void)conversationGroupResultsControllerWillChangeContent:(JCConversationGroupsResultsController *)controller;

- (void)conversationGroupResultsControllerDidChangeContent:(JCConversationGroupsResultsController *)controller;

@end

@interface JCFetchedResultsUpdate : NSObject

@property (nonatomic, strong) id object;
@property (nonatomic) NSUInteger row;

@end