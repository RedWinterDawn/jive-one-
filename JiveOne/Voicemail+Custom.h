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
+ (void)addVoicemails:(NSArray *)entryArray completed:(void (^)(BOOL success))completed;
+ (Voicemail *)addVoicemailEntry:(NSDictionary*)entry sender:(id)sender;//Used for sockets
+ (Voicemail *)addVoicemail:(NSDictionary*)dictionary withManagedContext:(NSManagedObjectContext *)context sender:(id)sender;
+ (Voicemail *)updateVoicemail:(Voicemail*)voicemail withDictionary:(NSDictionary*)dictionary managedContext:(NSManagedObjectContext *)context;
+ (Voicemail *)markVoicemailForDeletion:(NSString*)voicemailId managedContext:(NSManagedObjectContext*)context;
+ (BOOL)isVoicemailInDeletedList:(NSString*)voicemailId;
+ (BOOL)deleteVoicemail:(NSString*)voicemailId managedContext:(NSManagedObjectContext*)context;
+ (void)fetchVoicemailInBackground;
+ (void)saveVoicemailEtag:(NSInteger)etag managedContext:(NSManagedObjectContext*)context;
+ (NSInteger)getVoicemailEtag;
@end
