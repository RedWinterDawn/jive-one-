//
//  Voicemail+Custom.h
//  JiveOne
//
//  Created by Daniel George on 3/21/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "Voicemail.h"

@interface Voicemail (Custom)

#pragma mark - CRUD for ConversationEntry
+ (void)addVoicemails:(NSArray *)entryArray;
+ (Voicemail *)addVoicemailEntry:(NSDictionary*)entry;
+ (Voicemail *)addVoicemail:(NSDictionary*)dictionary withManagedContext:(NSManagedObjectContext *)context;
+ (Voicemail *)updateVoicemail:(Voicemail*)vmail withDictionary:(NSDictionary*)dictionary managedContext:(NSManagedObjectContext *)context;
+ (void)fetchVoicemailInBackground;

@end
