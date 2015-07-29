//
//  JCFetchedResultsController.m
//  JiveOne
//
//  Created by Robert Barclay on 7/27/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCFetchedResultsController.h"

@interface JCFetchedResultsUpdate : NSObject

@property (nonatomic, strong) id object;
@property (nonatomic) NSUInteger row;

@end

@interface JCFetchedResultsController() {
    BOOL _loaded;
    BOOL _doingBatchUpdate;
}

@end

@implementation JCFetchedResultsController

-(instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)context fetchRequest:(NSFetchRequest *)request
{
    if (self = [super init])
    {
        _managedObjectContext = context;
        _fetchRequest = request;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(managedObjectContextObjectsDidChange:)
                                                     name:NSManagedObjectContextObjectsDidChangeNotification
                                                   object:context];
    }
    return self;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Public Methods -

/**
 * Fetches a list of conversation group id's from the conversations. Take the array and build a
 * conversation group from the conversation id. sort the array using the sort descriptors of the
 * fetch request.
 */
- (BOOL)performFetch:(NSError**)error
{
    if (!self.fetchRequest) {
        return NO;
    }
    
    NSFetchRequest *request = self.fetchRequest;
    NSArray *objects = [self.managedObjectContext executeFetchRequest:request error:error];
    _fetchedObjects = [[self objectsForObjects:objects] sortedArrayUsingDescriptors:request.sortDescriptors].mutableCopy;
    return (_fetchedObjects != nil);
}

/**
 * Returns the object at the given index path from the fetch results object.
 */
-(id<NSObject>)objectAtIndexPath:(NSIndexPath *)indexPath
{
    if (_fetchedObjects && _fetchedObjects.count > indexPath.row) {
        return [_fetchedObjects objectAtIndex:indexPath.row];
    }
    return nil;
}

/**
 * Returns an indexPath for a given object in the fetched results.
 */
-(NSIndexPath *)indexPathForObject:(id<NSObject>)object
{
    if ([_fetchedObjects containsObject:object]) {
        return [NSIndexPath indexPathForRow:[_fetchedObjects indexOfObject:object] inSection:0];
    }
    return nil;
}

-(id<NSObject>)objectForObject:(id<NSObject>)object
{
    if ([object isKindOfClass:[NSManagedObject class]]) {
        NSManagedObject *managedObject = (NSManagedObject *)object;
        if ([managedObject.entity isKindOfEntity:_fetchRequest.entity]) {
            return managedObject;
        }
    }
    return nil;
}

-(NSArray *)objectsForObjects:(NSArray *)objects
{
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:objects.count];
    @autoreleasepool {
        for (id object in objects) {
            if ([object isKindOfClass:[NSDictionary class]]) {
                id<NSObject> newObject = [self objectForObject:object];
                if (newObject) {
                    [array addObject:newObject];
                }
            }
        }
    }
    return array;
}

-(BOOL)predicateEvaluatesToObject:(id<NSObject>)object
{
    if ([object isKindOfClass:[NSManagedObject class]]) {
        NSManagedObject *managedObject = (NSManagedObject *)object;
        if (_fetchRequest.predicate) {
            return [_fetchRequest.predicate evaluateWithObject:managedObject];
        }
    }
    return YES;
}

-(BOOL)checkIfSortingChangedForObject:(id<NSObject>)object
{
    if ([object isKindOfClass:[NSManagedObject class]]) {
        NSArray *sortKeys = [_fetchRequest.sortDescriptors valueForKey:@"key"];
        NSManagedObject *managedObject = (NSManagedObject *)object;
        if ([sortKeys count]) {
            NSArray *keys = managedObject.changedValues.allKeys;
            for (NSString *key in sortKeys) {
                if ([keys containsObject:key]) {
                    return YES;
                }
            }
        }
    }
    return NO;
}

- (void)updateResultsWithDictionary:(NSDictionary *)userInfo
{
    if (!_fetchRequest) {
        return;
    }
    
    NSArray *insertedObjects            = [[userInfo valueForKey:NSInsertedObjectsKey] allObjects];
    NSMutableArray *updatedObjects      = [[userInfo valueForKey:NSUpdatedObjectsKey] allObjects].mutableCopy;
    NSArray *refreshed                  = [[userInfo valueForKey:@"refreshed"] allObjects];
    if (refreshed) {
        if (!updatedObjects) {
            updatedObjects = refreshed.mutableCopy;
        }
        [updatedObjects addObjectsFromArray:refreshed];
    }
    NSArray *deletedObjects             = [[userInfo valueForKey:NSDeletedObjectsKey] allObjects];
    if (insertedObjects.count == 0 && updatedObjects.count == 0 && deletedObjects.count == 0) {
        return;
    }
    
    NSArray *fetchedObjects     = [NSMutableArray arrayWithArray:_fetchedObjects];
    NSMutableArray *inserted    = [NSMutableArray array];                           // objects to insert and sort at the end
    NSMutableArray *updated     = [NSMutableArray array];                           // updated objects that change the sorting of the array.
    NSMutableArray *deleted     = [NSMutableArray arrayWithArray:deletedObjects];   // Objects that should be deleted due to predicate changes.
    
    _doingBatchUpdate = NO;
    
    // Process updated first, since they will add to our indexes, but not cause resorting.
    for (NSManagedObject *insertedObject in insertedObjects)
    {
        id<NSObject> object = [self objectForObject:insertedObject];
        BOOL evaluates = [self predicateEvaluatesToObject:object];
        if (!object || !evaluates) {
            continue;
        }
        [inserted addObject:object];
    }
    
    for (id updatedObject in updatedObjects)
    {
        id<NSObject> object = [self objectForObject:updatedObject];
        if (!object) {
            continue;
        }
        
        BOOL predicateEvaluates = [self predicateEvaluatesToObject:object];
        NSUInteger index = [fetchedObjects indexOfObject:object];
        BOOL containsObject = (index != NSNotFound);
        
        // If the content array already contains the object but the update resulted in the predicate
        // no longer evaluating to TRUE, then it needs to be removed. We add to the deleted array.
        if (containsObject && !predicateEvaluates) {
            [deleted addObject:object];
        }
        
        // If the content array does not contain the object but the object's update resulted in the
        // predicate now evaluating to TRUE, then it needs to be inserted.
        else if (!containsObject && predicateEvaluates) {
            [inserted addObject:object];
        }
        
        // Check if the object's updated keys are in the sort keys
        // This means that the sorting would have to be updated
        else if (containsObject)
        {
            // Create a wrapper object that keeps track of the original index for later
            BOOL sortingChanged = [self checkIfSortingChangedForObject:updatedObject];
            if (sortingChanged) {
                JCFetchedResultsUpdate *update = [JCFetchedResultsUpdate new];
                update.row = index;
                update.object = object;
                [updated addObject:update];
            }
            
            // If there's no change in sorting then just update the object as-is
            else {
                [self didChangeObject:object
                              atIndex:index
                        forChangeType:NSFetchedResultsChangeUpdate
                             newIndex:index];
            }
        }
    }
    
    // Delete deleted objects.
    for (id deletedObject in deleted)
    {
        id<NSObject> object = [self objectForObject:deletedObject];
        if (!object) {
            continue;
        }
        
        NSUInteger index = [fetchedObjects indexOfObject:object];
        if (index == NSNotFound) {
            continue;
        }
        
        [_fetchedObjects removeObject:object];
        [self didChangeObject:object
                      atIndex:index
                forChangeType:NSFetchedResultsChangeDelete
                     newIndex:NSNotFound];
    }
    
    // If there were updated objects that changed the sorting then resort and notify the delegate of
    // changes for updated objects.
    NSArray *sortDescriptors = _fetchRequest.sortDescriptors;
    if (updated.count > 0 && sortDescriptors.count > 0)
    {
        [_fetchedObjects sortUsingDescriptors:sortDescriptors];
        for (JCFetchedResultsUpdate *update in updated)
        {
            NSUInteger newIndex = [_fetchedObjects indexOfObject:update.object];
            [self didChangeObject:update.object
                          atIndex:update.row
                    forChangeType:NSFetchedResultsChangeMove
                         newIndex:newIndex];
        }
    }
    
    // If there were inserted objects then insert them into the content array and resort
    if (inserted.count > 0)
    {
        for (id object in inserted) {
            if (![_fetchedObjects containsObject:object]) {
                [_fetchedObjects addObject:object];
            }
        }
        
        if (sortDescriptors.count)
        {
            [_fetchedObjects sortUsingDescriptors:sortDescriptors];
            [_fetchedObjects enumerateObjectsUsingBlock:^(NSManagedObject *object, NSUInteger idx, BOOL *stop) {
                if ([inserted containsObject:object]) {
                    [self didChangeObject:object
                                  atIndex:NSNotFound
                            forChangeType:NSFetchedResultsChangeInsert
                                 newIndex:idx];
                }
            }];
        }
        
        // If there are no sort descriptors, then the inserted objects will just be added to the end
        // of the array so we don't need to figure out what indexes they were inserted in
        else {
            NSUInteger objectsCount = [_fetchedObjects count];
            for (NSInteger i = (objectsCount - inserted.count); i < objectsCount; i++) {
                [self didChangeObject:[_fetchedObjects objectAtIndex:i]
                              atIndex:NSNotFound
                        forChangeType:NSFetchedResultsChangeInsert
                             newIndex:i];
            }
        }
    }

    // if delegateWillChangeContent: was called then delegateDidChangeContent: must also be called
    if (_doingBatchUpdate) {
        [self didChangeContent];
    }
}

#pragma mark - Notification Handlers -

- (void)managedObjectContextObjectsDidChange:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    if (!userInfo) {
        return;
    }
    
    [self updateResultsWithDictionary:userInfo];
}

#pragma mark - Private -

- (void)willChangeContent
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(controllerWillChangeContent:)]) {
        [self.delegate controllerWillChangeContent:self];
    }
}

- (void)didChangeObject:(id)anObject atIndex:(NSUInteger)index forChangeType:(NSFetchedResultsChangeType)type newIndex:(NSUInteger)newIndex
{
    if (!_doingBatchUpdate) {
        [self willChangeContent];
        _doingBatchUpdate = TRUE;
    }
    
    if (_delegate && [_delegate respondsToSelector:@selector(controller:didChangeObject:atIndexPath:forChangeType:newIndexPath:)]) {
        NSIndexPath *indexPath;
        if (index != NSNotFound) {
            indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        }
        
        NSIndexPath *newIndexPath;
        if (newIndex != NSNotFound) {
            newIndexPath = [NSIndexPath indexPathForRow:newIndex inSection:0];
        }
        [_delegate controller:self didChangeObject:anObject atIndexPath:indexPath forChangeType:type newIndexPath:newIndexPath];
    }
}

- (void)didChangeContent
{
    if (!_doingBatchUpdate) {
        return;
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(controllerDidChangeContent:)]) {
        [self.delegate controllerDidChangeContent:self];
    }
    _doingBatchUpdate = FALSE;
}

@end

@implementation JCFetchedResultsUpdate

@end
