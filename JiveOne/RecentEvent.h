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

// Attributes
@property (nonatomic, strong) NSDate *date;        // The date of the event.
@property (nonatomic, getter=isRead) bool read;    // Indicates whether the event has been read.

// Transient Attributes.
@property (nonatomic, weak) NSNumber *timestamp;
@property (nonatomic, readonly) NSString *formattedModifiedShortDate;
@property (nonatomic, readonly) NSString *formattedLongDate;
@property (nonatomic) long long unixTimestamp;
@property (nonatomic, readonly) NSString *detailText;

@end
