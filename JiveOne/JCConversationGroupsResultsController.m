//
//  JCConversationGroups.m
//  JiveOne
//
//  Created by Robert Barclay on 2/23/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCConversationGroupsResultsController.h"
#import "JCPhoneBook.h"
#import "Message.h"
#import "SMSMessage.h"
#import "LocalContact.h"

#import "SMSMessage+V5Client.h"
#import "JCUnknownNumber.h"
#import "JCSMSConversationGroup.h"

@interface JCConversationGroupsResultsController ()
{
    NSMutableArray *_fetchedObjects;
    JCPhoneBook *_phoneBook;
    PBX *_pbx;
    BOOL _loaded;
    BOOL _doingBatchUpdate;
}

@end

@implementation JCConversationGroupsResultsController

-(instancetype)initWithFetchRequest:(NSFetchRequest *)fetchRequest pbx:(PBX *)pbx managedObjectContext:(NSManagedObjectContext *)context
{
    return [self initWithFetchRequest:fetchRequest pbx:pbx managedObjectContext:context phoneBook:[JCPhoneBook sharedPhoneBook]];
}

-(instancetype)initWithFetchRequest:(NSFetchRequest *)fetchRequest pbx:(PBX *)pbx managedObjectContext:(NSManagedObjectContext *)context phoneBook:(JCPhoneBook *)phoneBook;
{
    self = [super init];
    if (self)
    {
        _phoneBook = phoneBook;
        _pbx = pbx;
        _fetchRequest = fetchRequest;
        _manageObjectContext = context;
        
        // Ensure we are expecting a dictionary result type for the core data fetch request.
        fetchRequest.resultType             = NSDictionaryResultType;
        fetchRequest.propertiesToGroupBy    = @[NSStringFromSelector(@selector(messageGroupId))];
        fetchRequest.propertiesToFetch      = @[NSStringFromSelector(@selector(messageGroupId))];
        
        // Observe for notification changes for SMS updates.
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reload) name:kSMSMessagesDidUpdateNotification object:nil];
    }
    return self;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

/**
 * Fetches a list of conversation group id's from the conversations. Take the array and build a 
 * conversation group from the conversation id. sort the array using the sort descriptors of the 
 * fetch request.
 */
-(BOOL)performFetch:(NSError *__autoreleasing *)error
{
    if (!_fetchRequest) {
        return FALSE;
    }
    
    @autoreleasepool {
        NSArray *conversationGroupIds = [_manageObjectContext executeFetchRequest:_fetchRequest error:error];
        NSArray *conversationGroups = [self conversationGroupsForConversationIds:conversationGroupIds pbx:_pbx context:_manageObjectContext];
        _fetchedObjects = [conversationGroups sortedArrayUsingDescriptors:_fetchRequest.sortDescriptors].mutableCopy;
    }
    return (_fetchedObjects != nil);
}

/**
 * Returns the object at the given index path from the fetch results object.
 */
-(id<JCConversationGroupObject>)objectAtIndexPath:(NSIndexPath *)indexPath
{
    if (_fetchedObjects && _fetchedObjects.count > indexPath.row) {
        return [_fetchedObjects objectAtIndex:indexPath.row];
    }
    return nil;
}

/**
 * Returns an indexPath for a given object in the fetched results.
 */
-(NSIndexPath *)indexPathForObject:(id<JCConversationGroupObject>)object
{
    if (![object conformsToProtocol:@protocol(JCConversationGroupObject)]) {
        return nil;
    }
    
    
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
        
        NSArray *conversationGroups = [self conversationGroupsForConversationIds:conversationGroupIds pbx:_pbx context:_manageObjectContext];
        NSMutableArray *inserted = [NSMutableArray array];
        NSMutableArray *moved = [NSMutableArray array];
        
        // Loop through the results, and see if they are insertions or updates.
        for (int index = 0; index < conversationGroups.count; index++)
        {
            id<JCConversationGroupObject> conversationGroup = [conversationGroups objectAtIndex:index];
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

-(NSArray *)conversationGroupsForConversationIds:(NSArray *)conversationIds pbx:(PBX *)pbx context:(NSManagedObjectContext *)context
{
    NSMutableArray *conversationGroups = [NSMutableArray arrayWithCapacity:conversationIds.count];
    @autoreleasepool {
        for (id object in conversationIds) {
            if ([object isKindOfClass:[NSDictionary class]]) {
                NSString *conversationGroupId = [((NSDictionary *)object) stringValueForKey:NSStringFromSelector(@selector(messageGroupId))];
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"messageGroupId = %@", conversationGroupId];
                Message *message = [Message MR_findFirstWithPredicate:predicate sortedBy:NSStringFromSelector(@selector(date)) ascending:NO inContext:context];
                if (!message) {
                    continue;
                }
                
                // If the message is from the 
                if ([message isKindOfClass:[SMSMessage class]]) {
                    SMSMessage *smsMessage = (SMSMessage *)message;
                    if (smsMessage.did.pbx != pbx) {
                        continue;
                    }
                    
                    id<JCPhoneNumberDataSource> phoneNumber = [_phoneBook localPhoneNumberForNumber:conversationGroupId name:smsMessage.localContact.name];
                    JCSMSConversationGroup *smsConversationGroup = [[JCSMSConversationGroup alloc] initWithName:smsMessage phoneNumber:phoneNumber];
                    [conversationGroups addObject:smsConversationGroup];
                } else {
                    
                    // TODO: for chat implement lookup here for chat, whatever we need to do here.
                    
                }
            }
        }
    }
    return conversationGroups;
}

@end

@implementation JCFetchedResultsUpdate


@end
                     
                     
