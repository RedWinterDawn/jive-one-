//
//  Contact.h
//  JiveOne
//
//  Created by Robert Barclay on 12/10/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "Extension.h"

@class PBX;
@class InternalExtensionGroup;
@class RecentLineEvent;
@class Conversation;

@interface InternalExtension : Extension

// Attributes
@property (nonatomic, retain) NSString *jiveUserId;
@property (nonatomic, getter=isFavorite) BOOL favorite;

// Relationships
@property (nonatomic, strong) NSSet *lineEvents;
@property (nonatomic, strong) NSSet *conversations;
@property (nonatomic, retain) NSSet *groups;
@property (nonatomic, retain) PBX *pbx;

@end

@interface InternalExtension (CoreDataGeneratedAccessors)

- (void)addLineEventsObject:(RecentLineEvent *)value;
- (void)removeLineEventsObject:(RecentLineEvent *)value;
- (void)addLineEvents:(NSSet *)values;
- (void)removeLineEvents:(NSSet *)values;

- (void)addConversationsObject:(Conversation *)value;
- (void)removeConversationsObject:(Conversation *)value;
- (void)addConversations:(NSSet *)values;
- (void)removeConversations:(NSSet *)values;

- (void)addGroupsObject:(InternalExtensionGroup *)value;
- (void)removeGroupsObject:(InternalExtensionGroup *)value;
- (void)addGroups:(NSSet *)values;
- (void)removeGroups:(NSSet *)values;

@end
