//
//  PBX.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 7/16/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface PBX : NSManagedObject

@property (nonatomic, retain) NSString * jrn;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * pbxId;
@property (nonatomic, retain) NSString * selfUrl;
@property (nonatomic, retain) NSNumber * v5;

@end
