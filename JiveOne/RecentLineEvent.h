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

#import "JCPhoneNumberDataSource.h"

@class InternalExtension, Line, PhoneNumber;

@interface RecentLineEvent : RecentEvent <JCPhoneNumberDataSource>

// Represent the name of the event, typically the Caller ID, or name of person creating the event.
@property (nonatomic, readwrite, strong) NSString *name;

// Represents the phone number the event came from.
@property (nonatomic, readwrite, strong) NSString *number;

// Relationships
@property (nonatomic, strong) InternalExtension *internalExtension;
@property (nonatomic, strong) Line *line;
@property (nonatomic, strong) NSSet *phoneNumbers;

@end

@interface RecentLineEvent (CoreDataGeneratedAccessors)

- (void)addPhoneNumbersObject:(PhoneNumber *)value;
- (void)removePhoneNumbersObject:(PhoneNumber *)value;
- (void)addPhoneNumbers:(NSSet *)values;
- (void)removePhoneNumbers:(NSSet *)values;

@end
