//
//  JCConversationGroups.m
//  JiveOne
//
//  Created by Robert Barclay on 2/23/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCMessageGroupsResultsController.h"

#import "PBX.h"
#import "JCPhoneBook.h"
#import "Message.h"
#import "PhoneNumber.h"
#import "JCMessageGroup.h"

@interface JCMessageGroupsResultsController () <JCMessageGroupDelegate>
{
    JCPhoneBook *_phoneBook;
    PBX *_pbx;
}

@end

@implementation JCMessageGroupsResultsController

-(instancetype)initWithFetchRequest:(NSFetchRequest *)fetchRequest pbx:(PBX *)pbx
{
    return [self initWithFetchRequest:fetchRequest pbx:pbx phoneBook:[JCPhoneBook sharedPhoneBook]];
}

-(instancetype)initWithFetchRequest:(NSFetchRequest *)fetchRequest pbx:(PBX *)pbx phoneBook:(JCPhoneBook *)phoneBook;
{
    self = [super initWithManagedObjectContext:pbx.managedObjectContext fetchRequest:fetchRequest];
    if (self)
    {
        _phoneBook = phoneBook;
        _pbx = pbx;
        
        // Ensure we are expecting a dictionary result type for the core data fetch request.
        fetchRequest.resultType             = NSDictionaryResultType;
        fetchRequest.propertiesToGroupBy    = @[NSStringFromSelector(@selector(messageGroupId))];
        fetchRequest.propertiesToFetch      = @[NSStringFromSelector(@selector(messageGroupId))];
    }
    return self;
}

-(id<NSObject>)objectForObject:(id<NSObject>)object
{
    if ([object isKindOfClass:[JCMessageGroup class]]) {
        return object;
    }
    else if([object isKindOfClass:[Message class]])
    {
        JCMessageGroup *messageGroup = [self getMessageGroupForMessageGroupId:((Message *)object).messageGroupId];
        [messageGroup markNeedUpdate];
        return messageGroup;
    }
    else if ([object isKindOfClass:[NSDictionary class]])
    {
        NSString *messageGroupId = [(NSDictionary *)object stringValueForKey:NSStringFromSelector(@selector(messageGroupId))];
        return [self getMessageGroupForMessageGroupId:messageGroupId];
    }
    return [super objectForObject:object];
}

-(BOOL)predicateEvaluatesToObject:(id<NSObject>)object
{
    if ([object isKindOfClass:[JCMessageGroup class]]) {
        JCMessageGroup *messageGroup = (JCMessageGroup *)object;
        NSArray *messages = messageGroup.messages;
        if (messages.count > 0) {
            for (Message *message in messages) {
                BOOL result = [super predicateEvaluatesToObject:message];
                if (result) {
                    return YES;
                }
            }
        }
        return NO;
    }
    return [super predicateEvaluatesToObject:object];
}

-(BOOL)checkIfSortingChangedForObject:(id<NSObject>)object
{
    if ([object isKindOfClass:[JCMessageGroup class]]) {
        JCMessageGroup *messageGroup = (JCMessageGroup *)object;
        BOOL needsSorting = messageGroup.needsSorting;
        [messageGroup markAsSorted];
        return needsSorting;
    }
    return [super checkIfSortingChangedForObject:object];
}

#pragma mark - Delegate Handlers -

#pragma mark JCMessageGroupDelegate

-(NSArray *)updateMessagesForMessageGroup:(JCMessageGroup *)messageGroup
{
    NSManagedObjectContext *context = self.managedObjectContext;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K = %@", NSStringFromSelector(@selector(messageGroupId)), messageGroup.messageGroupId];
    return [Message MR_findAllSortedBy:NSStringFromSelector(@selector(date)) ascending:NO withPredicate:predicate inContext:context];
}

#pragma mark - Private -

-(JCMessageGroup *)getMessageGroupForMessageGroupId:(NSString *)messageGroupId
{
    NSArray *messageGroups = self.fetchedObjects;
    for(JCMessageGroup *messageGroup in messageGroups ) {
        if([messageGroup.messageGroupId isEqualToString:messageGroupId]) {
            return messageGroup;
        }
    }
    return [self createMessageGroupWithGroupId:messageGroupId];
}

-(JCMessageGroup *)createMessageGroupWithGroupId:(NSString *)messageGroupId;
{
    JCMessageGroup *messageGroup = [[JCMessageGroup alloc] initWithMessageGroupId:messageGroupId];
    messageGroup.delegate = self;
    messageGroup.phoneNumber = [_phoneBook localPhoneNumberForPhoneNumber:messageGroup.phoneNumber context:self.managedObjectContext];
    [messageGroup markNeedUpdate];
    return messageGroup;
}

@end




