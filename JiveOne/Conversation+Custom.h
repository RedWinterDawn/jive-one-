//
//  Conversation+Custom.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 3/10/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "Conversation.h"

@interface Conversation (Custom)

+ (void)addConversations:(NSArray*)conversationArray;
+ (Conversation *)addConversation:(NSDictionary*)conversation;
+ (Conversation *)addConversation:(NSDictionary*)conversation withManagedContext:(NSManagedObjectContext *)context;
+ (Conversation *)updateConversation:(Conversation*)conversation withDictinonary:(NSDictionary*)dictionary managedContext:(NSManagedObjectContext *)context;
+ (void)saveConversationEtag:(NSInteger)etag managedContext:(NSManagedObjectContext*)context;
+ (NSNumber *)getConversationEtag;
@end
