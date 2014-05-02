//
//  ConversationEntry+Custom.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 3/10/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "Conversation+Custom.h"
#import "ConversationEntry+Custom.h"

@implementation ConversationEntry (Custom)

+ (NSArray *)RetrieveConversationEntryById:(NSString *)conversationId
{
    NSArray *conversations = [super MR_findByAttribute:@"conversationId" withValue:conversationId andOrderBy:@"createdDate" ascending:YES];
    return conversations;
}

#pragma mark - CRUD for ConversationEntry
+ (void)addConversationEntries:(NSArray *)entryArray
{
    NSManagedObjectContext *context = [NSManagedObjectContext MR_contextForCurrentThread];
    for (NSDictionary *entry in entryArray) {
        if ([entry isKindOfClass:[NSDictionary class]]) {
            [self addConversationEntry:entry withManagedContext:context];
        }
    }
}

+ (ConversationEntry *)addConversationEntry:(NSDictionary *)entry
{
    return [self addConversationEntry:entry withManagedContext:nil];
}

+ (ConversationEntry *)addConversationEntry:(NSDictionary*)entry withManagedContext:(NSManagedObjectContext *)context
{
    if (!context) {
        context = [NSManagedObjectContext MR_contextForCurrentThread];
    }
    
    ConversationEntry *convEntry;
    NSString *entryId =  entry[@"id"];
    NSArray *resultsForId = [ConversationEntry MR_findByAttribute:@"entryId" withValue:entryId];
    
    NSString *entryTempUrn = entry[@"tempUrn"];
    NSArray *resultsForTempUrn = [ConversationEntry MR_findByAttribute:@"tempUrn" withValue:entryTempUrn];
    
    // if there are results, we're updating, else we're creating
    if (resultsForId.count > 0) {
        convEntry = resultsForId[0];
        [self updateConversationEntry:convEntry withDictionary:entry managedContext:context];
    }
    else if(resultsForTempUrn.count>0){
        convEntry = resultsForTempUrn[0];
        [self updateConversationEntry:convEntry withDictionary:entry managedContext:context];
    }
    else {
        NSLog(@"No id or tempUrn found for this entry in core data. This should only happen if the user logged out or on a new install.");
        convEntry = [ConversationEntry MR_createInContext:context];
        convEntry.conversationId = entry[@"conversation"];
        convEntry.entityId = entry[@"entity"];
        convEntry.lastModified = [NSNumber numberWithLongLong:[entry[@"lastModified"] longLongValue]];
        convEntry.createdDate = [NSNumber numberWithLongLong:[entry[@"createdDate"] longLongValue]];
        convEntry.call = entry[@"call"];
        convEntry.file = entry[@"file"];
        convEntry.message = entry[@"message"];
        convEntry.mentions = entry[@"mentions"];
        convEntry.tags = entry[@"tags"];
        convEntry.deliveryDate = entry[@"deliveryDate"];
        convEntry.type = entry[@"type"];
        convEntry.urn = entry[@"urn"];
        convEntry.entryId = entry[@"id"];
        
        //Update Conversation LastModified
        Conversation *conversation = [Conversation MR_findFirstByAttribute:@"conversationId" withValue:convEntry.conversationId];
        if (conversation) {
            if (convEntry.lastModified > conversation.lastModified) {
                conversation.lastModified = convEntry.lastModified;
            }
        }
        
        //Save conversation entry
        [context MR_saveToPersistentStoreAndWait];
    }
    return convEntry;
}

+ (ConversationEntry *)updateConversationEntry:(ConversationEntry*)entry withDictionary:(NSDictionary*)dictionary managedContext:(NSManagedObjectContext *)context
{
    if (!context) {
        context = [NSManagedObjectContext MR_contextForCurrentThread];
    }
    
    // if last modified timestamps are the same, then there's no need to update anything.
    long long lastModifiedFromEntity = [entry.lastModified longLongValue];
    long long lastModifiedFromDictionary = [dictionary[@"lastModified"] longLongValue];
    
    if (lastModifiedFromDictionary > lastModifiedFromEntity) {
        
        entry.conversationId = dictionary[@"conversation"];
        entry.entityId = dictionary[@"entity"];
        entry.lastModified = [NSNumber numberWithLongLong:[dictionary[@"lastModified"] longLongValue]];
//        entry.createdDate = [NSNumber numberWithLongLong:[dictionary[@"createdDate"] longLongValue]];
        entry.call = dictionary[@"call"];
        entry.file = dictionary[@"file"];
        entry.message = dictionary[@"message"];
        entry.mentions = dictionary[@"mentions"];
        entry.tags = dictionary[@"tags"];
        entry.deliveryDate = dictionary[@"deliveryDate"];
        entry.type = dictionary[@"type"];
        entry.urn = dictionary[@"urn"];
        entry.entryId = dictionary[@"id"];
        
        //Save conversation entry
        [context MR_saveToPersistentStoreAndWait];
    }
    
    return entry;
}

@end
