//
//  Voicemail.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 7/16/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "RecentLineEvent.h"

extern NSString *const kVoicemailDataAttributeKey;

@class VoicemailTranscription;

@interface Voicemail : RecentLineEvent

// Primary Key
@property (nonatomic, strong) NSString * jrn;

@property (nonatomic) NSInteger duration;
@property (nonatomic) BOOL markForDeletion;

@property (nonatomic, retain) NSString * mailboxUrl;
@property (nonatomic, retain) NSString * url_changeStatus;
@property (nonatomic, retain) NSString * url_download;
@property (nonatomic, retain) NSString * url_pbx;
@property (nonatomic, retain) NSString * url_self;

@property (nonatomic, retain) NSData * data;

@property (nonatomic, readonly) NSString *displayExtension;
@property (nonatomic, readonly) NSString *displayDuration;

@property (nonatomic, retain) VoicemailTranscription *transcription;

@end
