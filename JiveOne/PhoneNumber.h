//
//  LocalContact.h
//  JiveOne
//
//  Created by Robert Barclay on 2/12/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCPhoneNumberManagedObject.h"
#import "JCAddressBookNumber.h"

@class Contact;
@class SMSMessage;
@class RecentLineEvent;

@interface PhoneNumber : JCPhoneNumberManagedObject

@property (nonatomic) NSInteger order;
@property (nonatomic, strong) NSString *type;

// Relationships
@property (nonatomic, retain) NSSet *smsMessages;
@property (nonatomic, retain) NSSet *lineEvents;
@property (nonatomic, retain) Contact *contact;

@property (nonatomic, strong) JCAddressBookNumber *phoneNumber;

@end

@interface PhoneNumber (CoreDataGeneratedAccessors)

- (void)addSmsMessagesObject:(SMSMessage *)value;
- (void)removeSmsMessagesObject:(SMSMessage *)value;
- (void)addSmsMessages:(NSSet *)values;
- (void)removeSmsMessages:(NSSet *)values;

- (void)addRecentLineEventsObject:(RecentLineEvent *)value;
- (void)removeRecentLineEventsObject:(RecentLineEvent *)value;
- (void)addRecentLineEvents:(NSSet *)values;
- (void)removeRecentLineEvents:(NSSet *)values;

@end

@interface PhoneNumber (JCAddressBook)

@end