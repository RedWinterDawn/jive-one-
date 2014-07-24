//
//  PersonEntities.h
//  JiveOne
//
//  Created by Daniel George on 4/29/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Company, PersonMeta, Presence;

@interface PersonEntities : NSManagedObject

@property (nonatomic, retain) NSString * email;
@property (nonatomic, retain) NSString * entityId;
@property (nonatomic, retain) NSString * externalId;
@property (nonatomic, retain) NSString * firstLastName;
@property (nonatomic, retain) id firstName;
@property (nonatomic, retain) id groups;
@property (nonatomic, retain) NSString * id;
@property (nonatomic, retain) NSNumber * isFavorite;
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
@property (nonatomic, retain) Company *entityCompany;
@property (nonatomic, retain) PersonMeta *entityMeta;
@property (nonatomic, retain) Presence *entityPresence;

@end
