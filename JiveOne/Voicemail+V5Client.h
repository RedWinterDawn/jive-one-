//
//  Voicemail+Custom.h
//  JiveOne
//
//  Created by Daniel George on 3/21/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "Voicemail.h"

@interface Voicemail (Custom)

// Retrives all voicemails for a line.
+ (void)downloadVoicemailsForLine:(Line *)line complete:(CompletionHandler)completed;

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


