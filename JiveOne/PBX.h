//
//  PBX.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 6/24/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface PBX : NSManagedObject

@property (nonatomic, retain) NSString * pbxId;
@property (nonatomic, retain) NSString * name;

@end
