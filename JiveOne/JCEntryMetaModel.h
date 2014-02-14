//
//  JCEntryMetaModel.h
//  JiveAppOne
//
//  Created by Eduardo Gueiros on 2/9/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JSONModel.h"

@interface JCEntryMetaModel : JSONModel

@property (assign, nonatomic) long lastModified;
@property (strong, nonatomic) NSString* _id;
@property (strong, nonatomic) NSString* conversation;
@property (strong, nonatomic) NSString* entity;
@property (assign, nonatomic) float __v;
@property (assign, nonatomic) long createdDate;
@property (assign, nonatomic) int unreadEntries;
@property (assign, nonatomic) BOOL favorite;
@property (assign, nonatomic) BOOL displayInList;
@property (assign, nonatomic) BOOL idle;
@property (strong, nonatomic) NSString* urn;
@property (strong, nonatomic) NSString* id;
@property (assign, nonatomic) long idleTime;

@end
