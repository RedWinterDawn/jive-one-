//
//  Voicemail+Custom.h
//  JiveOne
//
//  Created by Daniel George on 3/21/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "Voicemail.h"

@interface Voicemail (Custom)

+ (NSArray *)RetrieveConversationEntryById:(NSString *)conversationId;

#pragma mark - CRUD for ConversationEntry
+ (void)addVoicemails:(NSArray *)entryArray;
+ (Voicemail *)addVoicemailEntry:(NSDictionary*)entry;
+ (Voicemail *)addVoicemailEntry:(NSDictionary*)dictionary withManagedContext:(NSManagedObjectContext *)context;
+ (Voicemail *)updateVoicemailEntry:(Voicemail*)entry withDictionary:(NSDictionary*)dictionary managedContext:(NSManagedObjectContext *)context;


@end
