//
//  Voicemail+Custom.h
//  JiveOne
//
//  Created by Daniel George on 3/21/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "Voicemail.h"

@interface Voicemail (Custom)

// Core Data Helper functions
+ (Voicemail *)voicemailForIdentifier:(NSString *)identifier context:(NSManagedObjectContext *)context;
+ (void)saveVoicemailEtag:(NSInteger)etag managedContext:(NSManagedObjectContext*)context;
+ (NSInteger)getVoicemailEtag;

// Initiiates a V5 voicemail Fetch.
+ (void)fetchVoicemailsInBackground:(void(^)(BOOL success, NSError *error))completed;

// Used by the V5 Client.
+ (void)addVoicemails:(NSDictionary *)entryArray mailboxUrl:(NSString *)mailboxUrl completed:(void (^)(BOOL success))completed;

// Gets list of all voicemails that do not have data yet, and request the data asyncronously.
+ (void)fetchAllVoicemailDataInBackground;

// Synchronous Requests the Voicmail data using the download url.
- (void)fetchData;

// Marks the Voicemail as read, notifying the server. It marks the voicmail as read if it was able to successfully
// update the server.
- (void)markAsRead;

+ (void)deleteVoicemailsInBackground;
+ (BOOL)isVoicemailInDeletedList:(NSString*)voicemailId;
+ (BOOL)deleteVoicemail:(NSString*)voicemailId managedContext:(NSManagedObjectContext*)context;
+ (Voicemail *)markVoicemailForDeletion:(NSString*)voicemailId managedContext:(NSManagedObjectContext*)context;

@end


