//
//  Company.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 3/12/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Company : NSManagedObject

@property (nonatomic, retain) NSString * companyId;
@property (nonatomic, retain) NSNumber * createDate;
@property (nonatomic, retain) NSNumber * lastModified;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * pbxId;
@property (nonatomic, retain) NSString * timezone;
@property (nonatomic, retain) NSString * urn;

@end
