//
//  OutGoingCall.h
//  JiveOne
//
//  Created by P Leonard on 10/10/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface OutGoingCall : NSManagedObject

@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSString * callerNumber;
@property (nonatomic, retain) NSString * callerName;
@property (nonatomic, retain) NSNumber * callerExt;
@property (nonatomic, retain) NSManagedObject *newRelationship;

@end
