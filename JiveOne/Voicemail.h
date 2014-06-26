//
//  Voicemail.h
//  JiveOne
//
//  Created by Daniel George on 6/26/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Voicemail : NSManagedObject

@property (nonatomic, retain) NSString * callerId;
@property (nonatomic, retain) NSNumber * deleted;
@property (nonatomic, retain) NSNumber * duration;
@property (nonatomic, retain) NSString * jrn;
@property (nonatomic, retain) NSString * mailboxId;
@property (nonatomic, retain) NSString * transcriptionPercent;
@property (nonatomic, retain) NSString * transcription;
@property (nonatomic, retain) NSNumber * read;
@property (nonatomic, retain) NSData * voicemail;
@property (nonatomic, retain) NSString * url_self;
@property (nonatomic, retain) NSString * url_download;
@property (nonatomic, retain) NSString * url_changeStatus;
@property (nonatomic, retain) NSDate * timeStamp;

@end
