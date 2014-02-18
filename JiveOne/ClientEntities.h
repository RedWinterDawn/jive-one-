//
//  ClientEntities.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 2/18/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ClientMeta, Company;

@interface ClientEntities : NSManagedObject

@property (nonatomic, retain) NSString * company;
@property (nonatomic, retain) NSNumber * createDate;
@property (nonatomic, retain) NSString * email;
@property (nonatomic, retain) NSString * entityId;
@property (nonatomic, retain) NSString * firstLastName;
@property (nonatomic, retain) id firstName;
@property (nonatomic, retain) id groups;
@property (nonatomic, retain) NSString * id;
@property (nonatomic, retain) NSString * lastFirstName;
@property (nonatomic, retain) NSNumber * lastModified;
@property (nonatomic, retain) NSString * lastName;
@property (nonatomic, retain) id location;
@property (nonatomic, retain) NSString * picture;
@property (nonatomic, retain) NSString * presence;
@property (nonatomic, retain) id tags;
@property (nonatomic, retain) NSString * urn;
@property (nonatomic, retain) NSNumber * me;
@property (nonatomic, retain) NSString * externalId;
@property (nonatomic, retain) ClientMeta *entityMeta;
@property (nonatomic, retain) Company *entityCompany;

@end
