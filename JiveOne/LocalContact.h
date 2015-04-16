//
//  LocalContact.h
//  JiveOne
//
//  Created by Robert Barclay on 2/12/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCPersonManagedObject.h"
#import "JCAddressBookPerson.h"
#import "JCAddressBookNumber.h"

@class SMSMessage;
@class RecentLineEvent;

@interface LocalContact : JCPersonManagedObject

// Attributes
@property (nonatomic, strong) NSString *personHash;
@property (nonatomic) NSInteger personId;

// Relationships
@property (nonatomic, retain) NSSet *smsMessages;
@property (nonatomic, retain) NSSet *lineEvents;

@property (nonatomic, strong) JCAddressBookNumber *phoneNumber;

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

@interface LocalContact (JCAddressBook)

+(LocalContact *)localContactForAddressBookNumber:(JCAddressBookNumber *)addressBookNumber context:(NSManagedObjectContext *)context;

@end