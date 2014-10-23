//
//  Voicemail.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 7/16/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "RecentEvent.h"

@interface Voicemail : RecentEvent

@property (nonatomic, retain) NSString * callerId;
@property (nonatomic, retain) NSString * callerIdNumber;
@property (nonatomic, retain) NSNumber * markForDeletion;
@property (nonatomic, retain) NSNumber * duration;
@property (nonatomic, retain) NSString * jrn;
@property (nonatomic, retain) NSString * mailboxUrl;
@property (nonatomic, retain) NSNumber * read;
@property (nonatomic, retain) NSString * transcription;
@property (nonatomic, retain) NSString * transcriptionPercent;
@property (nonatomic, retain) NSString * url_changeStatus;
@property (nonatomic, retain) NSString * url_download;
@property (nonatomic, retain) NSString * url_pbx;
@property (nonatomic, retain) NSString * url_self;
@property (nonatomic, retain) NSData * voicemail;
@property (nonatomic, retain) NSNumber * voicemailId; 

@end
