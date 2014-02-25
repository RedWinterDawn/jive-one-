//
//  Presence.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 2/24/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Presence : NSManagedObject

@property (nonatomic, retain) NSString * presenceId;
@property (nonatomic, retain) NSString * entityId;
@property (nonatomic, retain) NSNumber * lastModified;
@property (nonatomic, retain) NSNumber * createDate;
@property (nonatomic, retain) id interactions;

@end
