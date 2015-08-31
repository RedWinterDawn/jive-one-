//
//  DID.h
//  JiveOne
//
//  Created by Robert Barclay on 2/12/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCPhoneNumberManagedObject.h"

@class PBX, SMSMessage, BlockedContact;

@interface DID : JCPhoneNumberManagedObject

// Attributes
@property (nonatomic, retain) NSString * jrn;
@property (nonatomic, getter=canMakeCall) BOOL makeCall;
@property (nonatomic, getter=canReceiveCall) BOOL receiveCall;
@property (nonatomic, getter=canSendSMS) BOOL sendSMS;
@property (nonatomic, getter=canReceiveSMS) BOOL receiveSMS;

// Transient
@property (nonatomic, readonly) NSString * didId;

// Relationships
@property (nonatomic, retain) PBX *pbx;
@property (nonatomic, retain) NSSet *smsMessages;
@property (nonatomic, retain) NSSet *blockedContacts;

@end

@interface DID (CoreDataGeneratedAccessors)

- (void)addSmsMessagesObject:(SMSMessage *)value;
- (void)removeSmsMessagesObject:(SMSMessage *)value;
- (void)addSmsMessages:(NSSet *)values;
- (void)removeSmsMessages:(NSSet *)values;

- (void)addBlockedContactsObject:(BlockedContact *)value;
- (void)removeBlockedContactsObject:(BlockedContact *)value;
- (void)addBlockedContacts:(NSSet *)values;
- (void)removeBlockedContacts:(NSSet *)values;

@end
