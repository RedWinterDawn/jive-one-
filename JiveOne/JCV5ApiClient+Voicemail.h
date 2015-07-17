//
//  JCV5ApiClient+Voicemail.h
//  JiveOne
//
//  Created by Robert Barclay on 7/16/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCV5ApiClient.h"

@class Voicemail;

@interface JCV5ApiClient (Voicemail)

+ (void)downloadVoicemailsForLine:(Line *)line
                       completion:(JCApiClientCompletionHandler)completion;

+ (void)updateVoicemail:(Voicemail *)voicemail
             completion:(JCApiClientCompletionHandler)completion;

+ (void)deleteVoicemail:(Voicemail *)voicemail
             completion:(JCApiClientCompletionHandler)completion;

@end
