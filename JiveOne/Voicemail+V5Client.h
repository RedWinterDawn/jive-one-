//
//  Voicemail+V5Client.h
//  JiveOne
//
//  Created by Daniel George on 3/21/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "Voicemail.h"

@interface Voicemail (V5Client)

// Downloads the voicemails audio file.
- (void)downloadVoicemailAudio:(CompletionHandler)completion;

// Marks the voicemail as having been read. Attempts to notify server of read status.
- (void)markAsRead:(CompletionHandler)completion;

// Marks the voicemail for deletion. Attempts to notify server of deletion.
- (void)markForDeletion:(CompletionHandler)completion;

// Retrives all voicemails for a line.
+ (void)downloadVoicemailsForLine:(Line *)line completion:(CompletionHandler)completion;

// Deletes all voicemails for a line.
+ (void)deleteAllMarkedVoicemailsForLine:(Line *)line completion:(CompletionHandler)completion;

// Marks voicemail as read on server using V5Client. Called by instance method markAsRead:
+ (void)markVoicemailAsRead:(Voicemail *)voicemail completion:(CompletionHandler)completion;

// Deletes voicemail on server using V5Client. Called by instance menthod markForDeletion:
+ (void)deleteVoicemail:(Voicemail *)voicemail completion:(CompletionHandler)completion;

@end


