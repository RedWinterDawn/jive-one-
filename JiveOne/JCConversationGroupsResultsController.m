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
}

@end

@implementation JCConversationGroupsResultsController

-(instancetype)initWithFetchRequest:(NSFetchRequest *)fetchRequest managedObjectContext:(NSManagedObjectContext *)context
{
    self = [super init];
    if (self) {
        _fetchRequest = fetchRequest;
        
        // Ensure we are expecting a dictionary result type for the core data fetch request.
        fetchRequest.resultType             = NSDictionaryResultType;
        fetchRequest.propertiesToGroupBy    = @[NSStringFromSelector(@selector(messageGroupId))];
        fetchRequest.propertiesToFetch      = @[NSStringFromSelector(@selector(messageGroupId))];
        
        _manageObjectContext = context;
        
        // Observe for notification changes.
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(reload)
                                                     name:kSMSMessagesDidUpdateNotification
                                                   object:nil];
    }
    return self;
}

-(BOOL)performFetch:(NSError *__autoreleasing *)error
{
    // Fetch the Core Data Results for the conversations in the fetched results view controller, and
    // build them into an array of conversation group objects.
    NSArray *results = [_manageObjectContext executeFetchRequest:_fetchRequest error:error];
    NSArray *fetchedObjects = [self conversationGroupsForConversationIds:results];
    
    // This is a first request, so we just populate the results, for them to be drawn.
    if (!_fetchedObjects) {
        _fetchedObjects = fetchedObjects.mutableCopy;
    }
    
    // This is an updated request, so we notify the delegate that we are making an update to the
    // results and loop through the results and try to calculate the new indexes of the inserted
    // conversation groups
    else {
        
        if (_delegate && [_delegate respondsToSelector:@selector(conversationGroupResultsControllerWillChangeContent:)]) {
            [_delegate conversationGroupResultsControllerWillChangeContent:self];
        }
        
        // Loop through the results, and see if they are insertions or updates.
        for (int row = 0; row < fetchedObjects.count; row++) {
            
            JCConversationGroup *conversation = [_fetchedObjects objectAtIndex:row];
            
            // Check to see if this conversation is an insertion. it is an insertion if there in not
            // a conversation with the same conversation id (determined by isEqual: through contains
            // object). If it is an insertion, add to our fetched objects array and provide the
            // insertion indexPath. The insertion indexPath and newIndexPath are the same.
            if (![_fetchedObjects containsObject:conversation]) {
            
                [_fetchedObjects addObject:conversation];
                if (_delegate && [_delegate respondsToSelector:@selector(conversationGroupResultsController:didChangeObject:atIndexPath:forChangeType:newIndexPath:)]) {
                    
                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
                    [_delegate conversationGroupResultsController:self
                                                  didChangeObject:conversation
                                                      atIndexPath:indexPath
                                                    forChangeType:JCConversationGroupsResultsChangeInsert
                                                     newIndexPath:indexPath]; // Index
                }
            }
            
            // We are updating this conversation group, it is not an insertion. It can be a update
            // or a change move event. Change move event would be when a new message comes in for an
            // older conversation, which would move it to the top because its sorted by date.
            else {
                
                // We get the index path of the object in the old fetched object (determined using
                // isEqual: through the indexOfObject: method) if the old row matches the new row,
                // then we are just updating the conversation id with likely a new last message.
                NSUInteger oldRow = [_fetchedObjects indexOfObject:conversation];
                if (oldRow == row) {
                    // we are just updating the data, and NOT changing rows.
                    [_fetchedObjects replaceObjectAtIndex:row withObject:conversation];
                    if (_delegate && [_delegate respondsToSelector:@selector(conversationGroupResultsController:didChangeObject:atIndexPath:forChangeType:newIndexPath:)]) {
                        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
                        [_delegate conversationGroupResultsController:self
                                                      didChangeObject:conversation
                                                          atIndexPath:indexPath
                                                        forChangeType:JCConversationGroupsResultsChangeUpdate
                                                         newIndexPath:indexPath];
                    }
                }
                else {
                    // we are updating the data, and changing rows.
                    [_fetchedObjects removeObjectAtIndex:oldRow];
                    [_fetchedObjects insertObject:conversation atIndex:row];
                    
                    if (_delegate && [_delegate respondsToSelector:@selector(conversationGroupResultsController:didChangeObject:atIndexPath:forChangeType:newIndexPath:)]) {
                        
                        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:oldRow inSection:0];
                        NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:row inSection:0];
                        [_delegate conversationGroupResultsController:self
                                                      didChangeObject:conversation
                                                          atIndexPath:indexPath
                                                        forChangeType:JCConversationGroupsResultsChangeMove
                                                         newIndexPath:newIndexPath];
                    }
                }
            }
        }
        
        if (_delegate && [_delegate respondsToSelector:@selector(conversationGroupResultsControllerDidChangeContent:)]) {
            [_delegate conversationGroupResultsControllerDidChangeContent:self];
        }
    }
    
    //TODO: integrate the addressbook to drive updates to the objects.
    [self fetchAddressBookNamesForConversationsGroups:fetchedObjects];
    
    if (!error) {
        return TRUE;
    }
    return FALSE;
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
    [self performFetch:nil];
}

-(NSArray *)conversationGroupsForConversationIds:(NSArray *)conversationIds
{
    NSMutableArray *conversationGroups = [NSMutableArray arrayWithCapacity:conversationIds.count];
    for (id object in conversationIds) {
        if ([object isKindOfClass:[NSDictionary class]]) {
            NSString *conversationGroupId = [((NSDictionary *)object) stringValueForKey:NSStringFromSelector(@selector(messageGroupId))];
            JCConversationGroup *conversationGroup = [[JCConversationGroup alloc] initWithConversationGroupId:conversationGroupId context:_manageObjectContext];
            [conversationGroups addObject:conversationGroup];
        }
    }
    return conversationGroups;
}

-(void)fetchAddressBookNamesForConversationsGroups:(NSArray *)conversationsGroups {
    
    // Get the numbers that we are querying for. They should only be SMS numbers which are the
    // default value matching the conversationGroupId.
    NSMutableSet *numbers = [NSMutableSet new];
    for (JCConversationGroup *conversationGroup in conversationsGroups) {
        if (conversationGroup.isSMS && [conversationGroup.name isEqualToString:conversationGroup.conversationGroupId]) {
            [numbers addObject:conversationGroup.conversationGroupId];
        }
    }
    
    // Only ask the address book if we have numbers to look up.
    if (numbers.count == 0) {
        return;
    }
    
    // get names for numbers.
    [JCAddressBook formattedNamesForNumbers:numbers
                                      begin:^{
                                          if (_delegate && [_delegate respondsToSelector:@selector(conversationGroupResultsControllerWillChangeContent:)]) {
                                              [_delegate conversationGroupResultsControllerWillChangeContent:self];
                                          }
                                      }
                                     number:^(NSString *name, NSString *number) {
                                         JCConversationGroup *conversationGroup = [self conversationGroupForConversationGroupId:number];
                                         conversationGroup.name = name;
                                         NSIndexPath *indexPath = [self indexPathForObject:conversationGroup];
                                         if (_delegate && [_delegate respondsToSelector:@selector(conversationGroupResultsController:didChangeObject:atIndexPath:forChangeType:newIndexPath:)]) {
                                             [_delegate conversationGroupResultsController:self
                                                                           didChangeObject:conversationGroup
                                                                               atIndexPath:indexPath
                                                                             forChangeType:JCConversationGroupsResultsChangeUpdate
                                                                              newIndexPath:indexPath];
                                         }
                                     }
                                 completion:^(BOOL success, NSError *error) {
                                     if (_delegate && [_delegate respondsToSelector:@selector(conversationGroupResultsControllerDidChangeContent:)]) {
                                         [_delegate conversationGroupResultsControllerDidChangeContent:self];
                                     }
                                 }];
}

-(JCConversationGroup *)conversationGroupForConversationGroupId:(NSString *)conversationGroupId
{
    for (JCConversationGroup *conversationGroup in _fetchedObjects) {
        if ([conversationGroup.conversationGroupId isEqualToString:conversationGroupId]) {
            return conversationGroup;
        }
    }
    return nil;
}

@end