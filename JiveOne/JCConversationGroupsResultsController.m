//
//  JCConversationGroups.m
//  JiveOne
//
//  Created by Robert Barclay on 2/23/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCConversationGroupsResultsController.h"
#import "JCAddressBook.h"
#import "Message.h"
#import "SMSMessage.h"
#import "LocalContact.h"

#import "JCConversationGroup.h"
#import "SMSMessage+SMSClient.h"

@interface JCConversationGroupsResultsController ()
{
    NSMutableArray *_fetchedObjects;
    PBX *_pbx;
    BOOL _loaded;
    BOOL _doingBatchUpdate;
}

@end

@implementation JCConversationGroupsResultsController

-(instancetype)initWithFetchRequest:(NSFetchRequest *)fetchRequest pbx:(PBX *)pbx managedObjectContext:(NSManagedObjectContext *)context
{
    self = [super init];
    if (self) {
        _fetchRequest = fetchRequest;
        
        // Ensure we are expecting a dictionary result type for the core data fetch request.
        fetchRequest.resultType             = NSDictionaryResultType;
        fetchRequest.propertiesToGroupBy    = @[NSStringFromSelector(@selector(messageGroupId))];
        fetchRequest.propertiesToFetch      = @[NSStringFromSelector(@selector(messageGroupId))];
        
        _pbx = pbx;
        
        _manageObjectContext = context;
        
        // Observe for notification changes for SMS updates.
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(reload)
                                                     name:kSMSMessagesDidUpdateNotification
                                                   object:nil];
    }
    return self;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(BOOL)performFetch:(NSError *__autoreleasing *)error
{
    if (!_fetchRequest) {
        return FALSE;
    }
    
    @autoreleasepool {
        // Fetch a list of conversation group ids.
        NSArray *conversationGroupIds = [_manageObjectContext executeFetchRequest:_fetchRequest error:error];
        
        // Fetch the Core Data Results for the conversations in the fetched results view controller,
        // and build them into an array of conversation group objects.
        NSArray *conversationGroups = [self conversationGroupsForConversationIds:conversationGroupIds];
        
        // Match address book contacts with conversation groups. If we have permission to the
        // address book, this method will be synchrounous. If we do not it will be asynchronous, and
        // treated as a table update.
        [self fetchAddressBookNamesForConversationsGroups:conversationGroups];
        _fetchedObjects = [conversationGroups sortedArrayUsingDescriptors:_fetchRequest.sortDescriptors].mutableCopy;
    }
    
    return (_fetchedObjects != nil);
}

-(id)objectAtIndexPath:(NSIndexPath *)indexPath
{
    if (_fetchedObjects && _fetchedObjects.count > indexPath.row) {
        return [_fetchedObjects objectAtIndex:indexPath.row];
    }
    return nil;
}

-(NSIndexPath *)indexPathForObject:(id)object
{
    if ([_fetchedObjects containsObject:object]) {
        return [NSIndexPath indexPathForRow:[_fetchedObjects indexOfObject:object] inSection:0];
    }
    return nil;
}

#pragma mark - Private -

-(void)reload
{
    if (!_fetchRequest) {
        return;
    }
    
    @autoreleasepool {
        __autoreleasing NSError *error;
        NSArray *conversationGroupIds = [_manageObjectContext executeFetchRequest:_fetchRequest error:&error];
        if (!conversationGroupIds) {
            NSLog(@"%@", error);
            return;
        }
        
        NSArray *conversationGroups = [self conversationGroupsForConversationIds:conversationGroupIds];
        NSMutableArray *inserted = [NSMutableArray array];
        NSMutableArray *moved = [NSMutableArray array];
        
        // Loop through the results, and see if they are insertions or updates.
        for (int index = 0; index < conversationGroups.count; index++)
        {
            JCConversationGroup *conversationGroup = [conversationGroups objectAtIndex:index];
            NSUInteger objectIndex = [_fetchedObjects indexOfObject:conversationGroup];
            BOOL containsObject = (objectIndex != NSNotFound);
            
            // Check to see if this conversation is an insertion. It is an insertion if there in not
            // a conversation group with the same conversation id (determined by isEqual: through
            // contains object). If it is an insertion, add to our internal fetched objects array
            // and to an update array.
            if (!containsObject)
            {
                [_fetchedObjects addObject:conversationGroup];
                [inserted addObject:conversationGroup];
            }
            
            // We are updating this conversation group, it is not an insertion. It can be a update
            // or a change move event. Change move event would be when a new message comes in for an
            // older conversation, which would move it to the top because its sorted by date. Since
            // the conversation group object itself is a new object but maps to the same content
            // grouping id, rather than updating the conversation group, we replace it with the new
            // conversation group. We do transfer the name, since otherwise we ould have
            else
            {
                JCConversationGroup *oldConversationGroup = [_fetchedObjects objectAtIndex:objectIndex];
                conversationGroup.name = oldConversationGroup.name;
                [_fetchedObjects replaceObjectAtIndex:objectIndex withObject:conversationGroup];
                
                // We get the index path of the object in the old fetched object (determined using
                // isEqual: through the indexOfObject: method) if the old row matches the new row,
                // then we are just updating the conversation id with likely a new last message. If
                // they are different rows, due to sorting, then we need to move it.
                
                if (objectIndex != index) {
                    JCFetchedResultsUpdate *move = [JCFetchedResultsUpdate new];
                    move.object = conversationGroup;
                    move.row = objectIndex;
                    [moved addObject:move];
                }
                else
                {
                    [self didChangeObject:conversationGroup
                                  atIndex:objectIndex
                            forChangeType:JCConversationGroupsResultsChangeUpdate
                                 newIndex:objectIndex];
                }
            }
        }
        
        for (JCFetchedResultsUpdate *movedObject in moved) {
            NSUInteger row = [_fetchedObjects indexOfObject:movedObject.object];
            [self didChangeObject:movedObject.object
                          atIndex:movedObject.row
                    forChangeType:JCConversationGroupsResultsChangeMove
                         newIndex:row];
        }
        
        [_fetchedObjects sortUsingDescriptors:_fetchRequest.sortDescriptors];
        [_fetchedObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if ([inserted containsObject:obj]) {
                [self didChangeObject:obj
                              atIndex:NSNotFound
                        forChangeType:JCConversationGroupsResultsChangeInsert
                             newIndex:idx];
            }
        }];
        
        // If we did any changes, notify of content change.
        [self didChangeContent];
        
        // Attach address book contact info for inserted conversation groups.
        [self fetchAddressBookNamesForConversationsGroups:_fetchedObjects];
    }
}

- (void)willChangeContent
{
    if (_delegate && [_delegate respondsToSelector:@selector(conversationGroupResultsControllerWillChangeContent:)]) {
        [_delegate conversationGroupResultsControllerWillChangeContent:self];
    }
}

- (void)didChangeObject:(id)anObject
            atIndex:(NSUInteger)index
          forChangeType:(JCConversationGroupsResultsChangeType)type
           newIndex:(NSUInteger)newIndex
{
    if (!_doingBatchUpdate) {
        [self willChangeContent];
        _doingBatchUpdate = TRUE;
    }
    
    if (_delegate && [_delegate respondsToSelector:@selector(conversationGroupResultsController:didChangeObject:atIndexPath:forChangeType:newIndexPath:)]) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:newIndex inSection:0];
        [_delegate conversationGroupResultsController:self didChangeObject:anObject atIndexPath:indexPath forChangeType:type newIndexPath:newIndexPath];
    }
}

- (void)didChangeContent
{
    if (!_doingBatchUpdate) {
        return;
    }
    
    if (_delegate && [_delegate respondsToSelector:@selector(conversationGroupResultsControllerDidChangeContent:)]) {
        [_delegate conversationGroupResultsControllerDidChangeContent:self];
    }
    _doingBatchUpdate = FALSE;
}

-(NSArray *)conversationGroupsForConversationIds:(NSArray *)conversationIds
{
    NSMutableArray *conversationGroups = [NSMutableArray arrayWithCapacity:conversationIds.count];
    @autoreleasepool {
        for (id object in conversationIds) {
            if ([object isKindOfClass:[NSDictionary class]]) {
                NSString *conversationGroupId = [((NSDictionary *)object) stringValueForKey:NSStringFromSelector(@selector(messageGroupId))];
                JCConversationGroup *conversationGroup = [[JCConversationGroup alloc] initWithConversationGroupId:conversationGroupId context:_manageObjectContext];
                if (conversationGroup.pbx == _pbx) {
                    [conversationGroups addObject:conversationGroup];
                }
            }
        }
    }
    return conversationGroups;
}

-(void)fetchAddressBookNamesForConversationsGroups:(NSArray *)conversationsGroups {
    
    // Get the numbers that we are querying for. They should only be SMS numbers which are the
    // default value matching the conversationGroupId.
    NSMutableSet *numbers = [NSMutableSet new];
    for (JCConversationGroup *conversationGroup in conversationsGroups) {
        if (conversationGroup.isSMS && !conversationGroup.name) {
            [numbers addObject:conversationGroup.conversationGroupId];
        }
    }
    
    // Only ask the address book if we have numbers to look up.
    if (numbers.count == 0) {
        return;
    }
    
    // get names for numbers.
    [[JCAddressBook sharedAddressBook] formattedNamesForNumbers:numbers
                                      begin:^{
                                          
                                      }
                                     number:^(NSString *name, NSString *number) {
                                         if (_fetchedObjects) {
                                             JCConversationGroup *conversationGroup = [JCConversationGroupsResultsController conversationGroupForConversationGroupId:number conversationGroups:_fetchedObjects];
                                             conversationGroup.name = name;
                                             NSUInteger index = [_fetchedObjects indexOfObject:conversationGroup];
                                             [self didChangeObject:conversationGroup
                                                           atIndex:index
                                                     forChangeType:JCConversationGroupsResultsChangeUpdate
                                                          newIndex:index];
                                         } else {
                                             JCConversationGroup *conversationGroup = [JCConversationGroupsResultsController conversationGroupForConversationGroupId:number conversationGroups:conversationsGroups];
                                             conversationGroup.name = name;
                                         }
                                     }
                                 completion:^(BOOL success, NSError *error) {
                                     if (success && _fetchedObjects) {
                                         [self didChangeContent];
                                     }
                                 }];
}

+(JCConversationGroup *)conversationGroupForConversationGroupId:(NSString *)conversationGroupId conversationGroups:(NSArray *)conversationGroups
{
    for (JCConversationGroup *conversationGroup in conversationGroups) {
        if ([conversationGroup.conversationGroupId isEqualToString:conversationGroupId]) {
            return conversationGroup;
        }
    }
    return nil;
}

@end

@implementation JCFetchedResultsUpdate


@end
                     
                     
