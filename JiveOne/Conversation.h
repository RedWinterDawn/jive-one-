//
//  Conversation.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 2/24/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Conversation : NSManagedObject

@property (nonatomic, retain) NSString * conversationId;
@property (nonatomic, retain) NSNumber * createdDate;
@property (nonatomic, retain) id entities;
@property (nonatomic, retain) NSString * group;
@property (nonatomic, retain) NSNumber * isGroup;
@property (nonatomic, retain) NSNumber * lastModified;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * urn;

@end
