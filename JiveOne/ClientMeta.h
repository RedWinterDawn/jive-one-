//
//  ClientMeta.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 3/12/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface ClientMeta : NSManagedObject

@property (nonatomic, retain) id activityOrder;
@property (nonatomic, retain) NSNumber * createDate;
@property (nonatomic, retain) NSString * entityId;
@property (nonatomic, retain) NSNumber * lastModified;
@property (nonatomic, retain) NSString * metaId;
@property (nonatomic, retain) id pinnedActivityOrder;
@property (nonatomic, retain) NSString * urn;

@end
