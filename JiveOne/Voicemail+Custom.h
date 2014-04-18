//
//  Voicemail+Custom.h
//  JiveOne
//
//  Created by Daniel George on 3/21/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "Voicemail.h"

@interface Voicemail (Custom)

#pragma mark - CRUD for Voicemail
+ (void)addVoicemails:(NSArray *)entryArray;
+ (Voicemail *)addVoicemailEntry:(NSDictionary*)entry;
+ (Voicemail *)addVoicemail:(NSDictionary*)dictionary withManagedContext:(NSManagedObjectContext *)context;
+ (Voicemail *)updateVoicemail:(Voicemail*)voicemail withDictionary:(NSDictionary*)dictionary managedContext:(NSManagedObjectContext *)context;
+ (Voicemail *)markVoicemailForDeletion:(NSString*)voicemailId managedContext:(NSManagedObjectContext*)context;
+ (BOOL)isVoicemailInDeletedList:(NSString*)voicemailId;
+ (BOOL)deleteVoicemail:(NSString*)voicemailId managedContext:(NSManagedObjectContext*)context;
+ (void)fetchVoicemailInBackground;

@end
