//
//  ClientEntities.h
//  JiveOne
//
//  Created by Doug Leonard on 4/8/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ClientMeta, Company, Presence;

@interface ClientEntities : NSManagedObject

@property (nonatomic, retain) NSNumber * createDate;
@property (nonatomic, retain) NSString * email;
@property (nonatomic, retain) NSString * entityId;
@property (nonatomic, retain) NSString * externalId;
@property (nonatomic, retain) NSString * firstLastName;
@property (nonatomic, retain) id firstName;
@property (nonatomic, retain) id groups;
@property (nonatomic, retain) NSString * id;
@property (nonatomic, retain) NSString * lastFirstName;
@property (nonatomic, retain) NSNumber * lastModified;
@property (nonatomic, retain) NSString * lastName;
@property (nonatomic, retain) id location;
@property (nonatomic, retain) NSNumber * me;
@property (nonatomic, retain) NSString * picture;
@property (nonatomic, retain) NSString * presence;
@property (nonatomic, retain) NSString * resourceGroupName;
@property (nonatomic, retain) id tags;
@property (nonatomic, retain) NSString * urn;
@property (nonatomic, retain) NSNumber * isFavorite;
@property (nonatomic, retain) Company *entityCompany;
@property (nonatomic, retain) ClientMeta *entityMeta;
@property (nonatomic, retain) Presence *entityPresence;

@end
