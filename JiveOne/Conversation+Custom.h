//
//  Conversation+Custom.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 3/10/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "Conversation.h"

@interface Conversation (Custom)

+ (void)addConversations:(NSArray*)conversationArray completed:(void (^)(BOOL success))completed;
+ (Conversation *)addConversation:(NSDictionary*)conversation sender:(id)sender;
+ (Conversation *)addConversation:(NSDictionary*)conversation withManagedContext:(NSManagedObjectContext *)context sender:(id)sender;
+ (Conversation *)updateConversation:(Conversation*)conversation withDictinonary:(NSDictionary*)dictionary managedContext:(NSManagedObjectContext *)context;
+ (void)saveConversationEtag:(NSInteger)etag managedContext:(NSManagedObjectContext*)context;
+ (NSInteger)getConversationEtag;
@end
