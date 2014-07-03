//
//  Mailbox.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 7/3/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class PBX, Voicemail;

@interface Mailbox : NSManagedObject

@property (nonatomic, retain) NSString * extensionName;
@property (nonatomic, retain) NSString * extensionNumber;
@property (nonatomic, retain) NSString * jrn;
@property (nonatomic, retain) NSString * url_self_mailbox;
@property (nonatomic, retain) NSString * url_pbx;
@property (nonatomic, retain) PBX *pbxMailbox;
@property (nonatomic, retain) Voicemail *voicemailMailbox;

@end
