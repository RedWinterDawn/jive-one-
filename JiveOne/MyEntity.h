//
//  MyEntity.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 2/17/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface MyEntity : NSManagedObject

@property (nonatomic, retain) NSString * presence;
@property (nonatomic, retain) NSString * email;
@property (nonatomic, retain) NSString * externalId;
@property (nonatomic, retain) NSString * company;
@property (nonatomic, retain) id location;
@property (nonatomic, retain) NSString * firstLastName;
@property (nonatomic, retain) NSString * urn;
@property (nonatomic, retain) id groups;
@property (nonatomic, retain) NSString * id;
@property (nonatomic, retain) NSString * picture;

@end
