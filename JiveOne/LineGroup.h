//
//  LineGroup.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 7/9/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface LineGroup : NSManagedObject

@property (nonatomic, retain) NSString * groupId;
@property (nonatomic, retain) NSString * lineId;

@end
