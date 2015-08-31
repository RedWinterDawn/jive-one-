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
        fetchRequest.propertiesToGroupBy    = @[NSStringFromSelector(@selector(messageGroupId)), NSStringFromSelector(@selector(resourceId))];
        fetchRequest.propertiesToFetch      = @[NSStringFromSelector(@selector(messageGroupId)), NSStringFromSelector(@selector(resourceId))];
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
        Message *message = (Message *)object;
        JCMessageGroup *messageGroup = [self getMessageGroupForMessageGroupId:message.messageGroupId resourceId:message.resourceId];
        [messageGroup markNeedUpdate];
        return messageGroup;
    }
    else if ([object isKindOfClass:[NSDictionary class]])
    {
        NSString *messageGroupId = [(NSDictionary *)object stringValueForKey:NSStringFromSelector(@selector(messageGroupId))];
        NSString *resourceId     = [(NSDictionary *)object stringValueForKey:NSStringFromSelector(@selector(resourceId))];
        return [self getMessageGroupForMessageGroupId:messageGroupId resourceId:resourceId];
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
    NSPredicate *predicate = [Message predicateForMessagesWithGroupId:messageGroup.groupId resourceId:messageGroup.resourceId pbxId:_pbx.pbxId];
    return [Message MR_findAllSortedBy:NSStringFromSelector(@selector(date)) ascending:NO withPredicate:predicate inContext:context];
}

#pragma mark - Private -

-(JCMessageGroup *)getMessageGroupForMessageGroupId:(NSString *)messageGroupId resourceId:(NSString *)resourceId
{
    NSArray *messageGroups = self.fetchedObjects;
    for(JCMessageGroup *messageGroup in messageGroups ) {
        if([messageGroup.groupId isEqualToString:messageGroupId] && [messageGroup.resourceId isEqualToString:resourceId]) {
            return messageGroup;
        }
    }
    return [self createMessageGroupWithGroupId:messageGroupId resourceId:resourceId];
}

-(JCMessageGroup *)createMessageGroupWithGroupId:(NSString *)groupId resourceId:(NSString *)resourceId;
{
    JCMessageGroup *messageGroup = [[JCMessageGroup alloc] initWithGroupId:groupId resourceId:resourceId];
    messageGroup.delegate = self;
    messageGroup.phoneNumber = [_phoneBook localPhoneNumberForPhoneNumber:messageGroup.phoneNumber context:self.managedObjectContext];
    [messageGroup markNeedUpdate];
    return messageGroup;
}

@end




