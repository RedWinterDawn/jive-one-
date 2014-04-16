//
//  Voicemail.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 4/16/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Voicemail : NSManagedObject

@property (nonatomic, retain) NSString * callerId;
@property (nonatomic, retain) NSNumber * createdDate;
@property (nonatomic, retain) NSNumber * lenght;
@property (nonatomic, retain) NSString * extensionNumber;
@property (nonatomic, retain) NSString * origFile;
@property (nonatomic, retain) NSNumber * lastModified;
@property (nonatomic, retain) NSString * messageId;
@property (nonatomic, retain) NSNumber * read;
@property (nonatomic, retain) NSString * urn;
@property (nonatomic, retain) NSData * voicemail;
@property (nonatomic, retain) NSString * file;
@property (nonatomic, retain) NSString * voicemailId;
@property (nonatomic, retain) NSString * callerNumber;
@property (nonatomic, retain) NSString * callerName;
@property (nonatomic, retain) NSString * pbxId;
@property (nonatomic, retain) NSString * lineId;
@property (nonatomic, retain) NSString * mailboxId;
@property (nonatomic, retain) NSString * folderId;
@property (nonatomic, retain) NSString * extensionName;

@end
