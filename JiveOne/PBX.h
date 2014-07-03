//
//  PBX.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 7/3/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Mailbox;

@interface PBX : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * pbxId;
@property (nonatomic, retain) NSString * jrn;
@property (nonatomic, retain) NSNumber * v5;
@property (nonatomic, retain) NSString * selfUrl;
@property (nonatomic, retain) Mailbox *mailboxPBX;

@end
