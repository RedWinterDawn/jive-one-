//
//  LocalContact.h
//  JiveOne
//
//  Created by Robert Barclay on 2/12/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "Person.h"

@class SMSMessage;
@class RecentLineEvent;

@interface LocalContact : Person

// Attributes
@property (nonatomic, readwrite, retain) NSString * number;
@property (nonatomic, retain) NSNumber * personId;

// Relationships
@property (nonatomic, retain) NSSet *smsMessages;
@property (nonatomic, retain) NSSet *lineEvents;

@end

@interface LocalContact (CoreDataGeneratedAccessors)

- (void)addSmsMessagesObject:(SMSMessage *)value;
- (void)removeSmsMessagesObject:(SMSMessage *)value;
- (void)addSmsMessages:(NSSet *)values;
- (void)removeSmsMessages:(NSSet *)values;

- (void)addRecentLineEventsObject:(RecentLineEvent *)value;
- (void)removeRecentLineEventsObject:(RecentLineEvent *)value;
- (void)addRecentLineEvents:(NSSet *)values;
- (void)removeRecentLineEvents:(NSSet *)values;

@end
