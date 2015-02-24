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

@implementation JCConversationGroupsResultsController

-(instancetype)initWithFetchRequest:(NSFetchRequest *)fetchRequest managedObjectContext:(NSManagedObjectContext *)context
{
    self = [super init];
    if (self) {
        _fetchRequest = fetchRequest;
        
        // Ensure we are expecting a dictionary result type for the core data fetch request.
        fetchRequest.resultType = NSDictionaryResultType;
        fetchRequest.propertiesToGroupBy = @[NSStringFromSelector(@selector(messageGroupId))];
        fetchRequest.propertiesToFetch = @[NSStringFromSelector(@selector(messageGroupId))];
        
        _manageObjectContext = context;
    }
    return self;
}

-(BOOL)performFetch:(NSError *__autoreleasing *)error
{
    if (_delegate && [_delegate respondsToSelector:@selector(conversationGroupResultsControllerWillChangeContent:)]) {
        [_delegate conversationGroupResultsControllerWillChangeContent:self];
    }
    
    // Fetch the Core Data Results for the conversations in the fetched results view controller, and
    // build them into an array of conversation group objects.
    NSArray *results = [_manageObjectContext executeFetchRequest:_fetchRequest error:error];
    _fetchedObjects = [self conversationGroupsForConversationIds:results];
    
    // TODO: Since the process of getting permission to the address book can be asynchronous, we can
    // not depend on imediate execution. so we attempt to do it here, and put it onto a seperate
    // thread, to dynamically load it in when it is ready and needed.
    
    
    if (_delegate && [_delegate respondsToSelector:@selector(conversationGroupResultsControllerDidChangeContent:)]) {
        [_delegate conversationGroupResultsControllerDidChangeContent:self];
    }
    
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

-(NSArray *)conversationGroupsForConversationIds:(NSArray *)conversationIds
{
    NSMutableArray *conversationGroups = [NSMutableArray arrayWithCapacity:conversationIds.count];
    for (id object in conversationIds) {
        if ([object isKindOfClass:[NSDictionary class]]) {
            NSString *conversationGroupId = [((NSDictionary *)object) stringValueForKey:NSStringFromSelector(@selector(messageGroupId))];
            JCConversationGroup *conversationGroup = [[JCConversationGroup alloc] initWithConversationId:conversationGroupId];
            
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"messageGroupId = %@", conversationGroupId];
            Message *message = [Message MR_findFirstWithPredicate:predicate sortedBy:NSStringFromSelector(@selector(date)) ascending:NO];
            if (message) {
                conversationGroup.lastMessage = message.text;
                conversationGroup.lastMessageReceived = message.date;
                NSString *name = conversationGroup.name;
                if (name) {
                    conversationGroup.name = name;
                }
                else {
                    
                    if ([message isKindOfClass:[SMSMessage class]]) {
                        SMSMessage *smsMessage = (SMSMessage *)message;
                        [conversationGroup addObserver:self forKeyPath:NSStringFromSelector(@selector(name)) options:0 context:NULL];
                        conversationGroup.name = smsMessage.localContact.number;
                    } else {
                        
                    }
                }
            }
            [conversationGroups addObject:conversationGroup];
        }
    }
    return conversationGroups;
}

// Observe when the value changes for the objects.

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(name))] && [object isKindOfClass:[JCConversationGroup class]]) {
        JCConversationGroup *conversationGroup = (JCConversationGroup *)object;
        NSLog(@"%@", conversationGroup);
    }
}

@end