//
//  Conversation+Custom.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 3/10/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "Conversation+Custom.h"
#import "ConversationETag.h"
#import "ConversationEntry+Custom.h"

@implementation Conversation (Custom)

#pragma mark - CRUD for Conversation
+ (void)addConversations:(NSArray *)conversationArray
{
    NSManagedObjectContext *context = [NSManagedObjectContext MR_contextForCurrentThread];
    for (NSDictionary *conversation in conversationArray) {
        [self addConversation:conversation withManagedContext:context];
    }
}

+ (Conversation *)addConversation:(NSDictionary*)conversation
{
    return [self addConversation:conversation withManagedContext:nil];
}

+ (Conversation *)addConversation:(NSDictionary *)conversation withManagedContext:(NSManagedObjectContext *)context
{
    if (!context) {
        context = [NSManagedObjectContext MR_contextForCurrentThread];
    }
    // check if we already have that conversation
    NSArray *result = [Conversation MR_findByAttribute:@"conversationId" withValue:conversation[@"id"]];
    Conversation *conv;
    if (result.count > 0) {
        conv = result[0];
        [self updateConversation:conv withDictinonary:conversation managedContext:context];
    }
    else {
        //if ([conversation[@"entries"] count] > 0) {
        
        
        conv = [Conversation MR_createInContext:context];
        conv.hasEntries = [NSNumber numberWithBool:([conversation[@"entries"] count] > 0)];
        conv.createdDate = [NSNumber numberWithLongLong:[conversation[@"createdDate"] longLongValue]];
        conv.lastModified = [NSNumber numberWithLongLong:[conversation[@"lastModified"] longLongValue]];
        conv.urn = conversation[@"urn"];
        conv.conversationId = conversation[@"id"];
        
        if (conversation[@"name"]) {
            conv.isGroup = [NSNumber numberWithBool:YES];
            conv.group = conversation[@"group"] ? conversation[@"group"] : nil;
            conv.name = conversation[@"name"];
        }
        //else {
        conv.entities = conversation[@"entities"];
        //}
        
        // Save conversation
        [context MR_saveToPersistentStoreAndWait];
        
        [ConversationEntry addConversationEntries:conversation[@"entries"]];
        
        //}
    }
    return conv;
}

+ (Conversation *)updateConversation:(Conversation*)conversation withDictinonary:(NSDictionary*)dictionary managedContext:(NSManagedObjectContext *)context
{
    if (!context) {
        context = [NSManagedObjectContext MR_contextForCurrentThread];
    }
    // if last modified timestamps are the same, then there's no need to update anything.
    long lastModifiedFromEntity = [conversation.lastModified integerValue];
    long lastModifiedFromDictionary = [dictionary[@"lastModified"] integerValue];
    
    if (lastModifiedFromDictionary > lastModifiedFromEntity) {
        conversation.lastModified = [NSNumber numberWithLongLong:[dictionary[@"lastModified"] longLongValue]];
        conversation.hasEntries = [NSNumber numberWithBool:([dictionary[@"entries"] count] > 0)];
        
        if (dictionary[@"name"]) {
            conversation.isGroup = [NSNumber numberWithBool:YES];
            conversation.group = dictionary[@"group"] ? dictionary[@"group"] : nil;
            conversation.name = dictionary[@"name"];
        }
        else {
            conversation.entities = dictionary[@"entities"];
        }
        
        // Save conversation
        [context MR_saveToPersistentStoreAndWait];
        
        // Save/Update entries
        [ConversationEntry addConversationEntries:dictionary[@"entries"]];
    }
    
    return conversation;
}

+ (void)saveConversationEtag:(NSInteger)etag managedContext:(NSManagedObjectContext*)context
{
    if (!context) {
        context = [NSManagedObjectContext MR_contextForCurrentThread];
    }
    
    ConversationETag *currentETag = [ConversationETag MR_findFirst];
    if (!currentETag) {
        currentETag = [ConversationETag MR_createEntity];
    }
    
    if (etag > [currentETag.etag integerValue]) {
        currentETag.etag = [NSNumber numberWithInteger:etag];
        [context MR_saveToPersistentStoreAndWait];
    }
}

+ (NSNumber *)getConversationEtag
{
    ConversationETag *currentETag = [ConversationETag MR_findFirst];
    if (currentETag) {
        return currentETag.etag;
    }
    else {
        return 0;
    }
}


@end
