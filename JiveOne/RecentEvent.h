//
//  RecentEvent.h
//  JiveOne
//
//  Created by P Leonard on 10/13/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Line;
@class Contact;

@interface RecentEvent : NSManagedObject

// Attributes
@property (nonatomic, strong) NSString * name;      // Represent the name of the event, typically the Caller ID, or name of person creating the event.
@property (nonatomic, strong) NSString * number;    // Represents the number the event came from.
@property (nonatomic, strong) NSDate *date;         // Represent the date of the event.
@property (nonatomic, getter=isRead) bool read;     // Indicates whether the event has been read.

// Transient Attributes.
@property (nonatomic, weak) NSNumber *timestamp;
@property (nonatomic, readonly) NSString *formattedModifiedShortDate;
@property (nonatomic, readonly) NSString *formattedLongDate;
@property (nonatomic) long long unixTimestamp;
@property (nonatomic, readonly) NSString *displayName;
@property (nonatomic, readonly) NSString *displayNumber;

// Relationships
@property (nonatomic, retain) Line *line;
@property (nonatomic, retain) Contact *contact;

@end
