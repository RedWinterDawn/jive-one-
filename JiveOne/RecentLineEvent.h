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

@class Contact, Line, LocalContact;

@interface RecentLineEvent : RecentEvent <JCPhoneNumberDataSource>

// Represent the name of the event, typically the Caller ID, or name of person creating the event.
@property (nonatomic, readwrite, strong) NSString *name;

// Represents the phone number the event came from.
@property (nonatomic, readwrite, strong) NSString *number;

// Relationships
@property (nonatomic, strong) Contact *contact;
@property (nonatomic, strong) Line *line;
@property (nonatomic, strong) NSSet *localContacts;

@end

@interface RecentLineEvent (CoreDataGeneratedAccessors)

- (void)addLocalContactsObject:(LocalContact *)value;
- (void)removeLocalContactsObject:(LocalContact *)value;
- (void)addLocalContacts:(NSSet *)values;
- (void)removeLocalContacts:(NSSet *)values;

@end
