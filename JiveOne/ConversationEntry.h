//
//  ConversationEntry.h
//  JiveOne
//
//  Created by Daniel George on 4/29/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface ConversationEntry : NSManagedObject

@property (nonatomic, retain) id call;
@property (nonatomic, retain) NSString * conversationId;
@property (nonatomic, retain) NSNumber * createdDate;
@property (nonatomic, retain) NSString * deliveryDate;
@property (nonatomic, retain) NSString * entityId;
@property (nonatomic, retain) NSString * entryId;
@property (nonatomic, retain) id file;
@property (nonatomic, retain) NSNumber * lastModified;
@property (nonatomic, retain) id mentions;
@property (nonatomic, retain) id message;
@property (nonatomic, retain) id tags;
@property (nonatomic, retain) NSString * tempUrn;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSString * urn;
@property (nonatomic, retain) NSNumber * failedToSend;

@end
