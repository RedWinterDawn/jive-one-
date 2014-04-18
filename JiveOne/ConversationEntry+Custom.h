//
//  ConversationEntry+Custom.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 3/10/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "ConversationEntry.h"

@interface ConversationEntry (Custom)

+ (NSArray *)RetrieveConversationEntryById:(NSString *)conversationId;

#pragma mark - CRUD for ConversationEntry
+ (void)addConversationEntries:(NSArray *)entryArray;
+ (ConversationEntry *)addConversationEntry:(NSDictionary*)entry;
+ (ConversationEntry *)addConversationEntry:(NSDictionary*)entry withManagedContext:(NSManagedObjectContext *)context;
+ (ConversationEntry *)updateConversationEntry:(ConversationEntry*)entry withDictionary:(NSDictionary*)dictionary managedContext:(NSManagedObjectContext *)context;

@end
