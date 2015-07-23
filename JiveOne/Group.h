//
//  Group.h
//  JiveOne
//
//  Created by Robert Barclay on 6/22/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "JCGroupDataSource.h"

@interface Group : NSManagedObject <JCGroupDataSource>

// Attributes
@property (nonatomic, strong) NSString * name;
@property (nonatomic, strong) NSString * groupId;

@end
