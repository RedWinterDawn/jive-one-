//
//  Lines.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 7/7/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Lines : NSManagedObject

@property (nonatomic, retain) NSString * displayName;
@property (nonatomic, retain) NSString * externsionNumber;
@property (nonatomic, retain) id groups;
@property (nonatomic, retain) NSString * jrn;
@property (nonatomic, retain) NSString * lineId;
@property (nonatomic, retain) NSString * pbxId;
@property (nonatomic, retain) NSString * userName;
@property (nonatomic, retain) NSNumber * state;

@end
