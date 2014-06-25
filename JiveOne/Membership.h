//
//  Membership.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 6/25/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Membership : NSManagedObject

@property (nonatomic, retain) NSString * jiveId;
@property (nonatomic, retain) NSString * pbxId;
@property (nonatomic, retain) NSString * membershipId;

@end
