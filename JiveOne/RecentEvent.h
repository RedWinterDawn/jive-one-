//
//  RecentEvent.h
//  JiveOne
//
//  Created by P Leonard on 10/13/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface RecentEvent : NSManagedObject

@property (nonatomic, strong) NSDate *date;

@property (nonatomic, assign) NSNumber *timestamp;
@property (nonatomic) long long unixTimestamp;

@property (nonatomic, readonly) NSString *formattedModifiedShortDate;
@property (nonatomic, readonly) NSString *formattedLongDate;

@end
