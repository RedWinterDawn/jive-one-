//
//  RecentLineEvent.h
//  JiveOne
//
//  Created by Robert Barclay on 2/12/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "RecentEvent.h"

@class Contact, Line;

@interface RecentLineEvent : RecentEvent

// Represents the phone number the event came from.
@property (nonatomic, retain) NSString *number;

// Represents the extension the event came from.
@property (nonatomic, retain) NSString *extension;

// Represent the name of the event, typically the Caller ID, or name of person creating the event.
@property (nonatomic, retain) NSString *name;

// Transient Properties.
@property (nonatomic, readonly) NSString *displayName;
@property (nonatomic, readonly) NSString *displayNumber;

// Relationships
@property (nonatomic, retain) Contact *contact;
@property (nonatomic, retain) Line *line;

@end
