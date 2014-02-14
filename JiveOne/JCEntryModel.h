//
//  JCEntryModel.h
//  JiveAppOne
//
//  Created by Eduardo Gueiros on 2/9/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JSONModel.h"
#import "JCEntryMetaModel.h"

@interface JCEntryModel : JSONModel

@property (strong, nonatomic) NSString* _id;
@property (assign, nonatomic) long lastModified;
@property (strong, nonatomic) NSString* tempUrn;
@property (strong, nonatomic) NSString* conversation;
@property (strong, nonatomic) NSString* entity;
@property (assign, nonatomic) float __v;
@property (assign, nonatomic) long createdDate;
@property (strong, nonatomic) NSObject   <Optional> *file;
@property (strong, nonatomic) NSObject  <Optional> *message;
@property (strong, nonatomic) NSObject   <Optional> *mentions;
@property (strong, nonatomic) NSObject   <Optional> *tags;
@property (strong, nonatomic) NSString* deliveryDate;
@property (strong, nonatomic) NSString* type;
@property (strong, nonatomic) NSString* urn;
@property (strong, nonatomic) NSString* id;
@property (strong, nonatomic) JCEntryMetaModel <Optional> * meta;

@end
