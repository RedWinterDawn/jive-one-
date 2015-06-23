//
//  Contact.h
//  JiveOne
//
//  Created by Robert Barclay on 6/5/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCPersonManagedObject.h"

@class PhoneNumber, Address, ContactInfo, User, ContactGroup;

@interface Contact : JCPersonManagedObject

// Attributes
@property (nonatomic, strong) NSString *contactId;
@property (nonatomic, getter=isMarkedForDeletion) BOOL markForDeletion;
@property (nonatomic, getter=isMarkedForUpdate) BOOL markForUpdate;
@property (nonatomic) NSInteger etag;

// Relationships
@property (nonatomic, strong) NSSet *contactGroups;
@property (nonatomic, retain) NSSet *phoneNumbers;
@property (nonatomic, retain) NSSet *addresses;
@property (nonatomic, retain) NSSet *info;
@property (nonatomic, retain) User *user;

@end

@interface Contact (CoreDataGeneratedAccessors)

- (void)addPhoneNumbersObject:(PhoneNumber *)value;
- (void)removePhoneNumbersObject:(PhoneNumber *)value;
- (void)addPhoneNumbers:(NSSet *)values;
- (void)removePhoneNumbers:(NSSet *)values;

- (void)addAddressesObject:(Address *)value;
- (void)removeAddressesObject:(Address *)value;
- (void)addAddresses:(NSSet *)values;
- (void)removeAddresses:(NSSet *)values;

- (void)addInfoObject:(ContactInfo *)value;
- (void)removeInfoObject:(ContactInfo *)value;
- (void)addInfo:(NSSet *)values;
- (void)removeInfo:(NSSet *)values;

- (void)addContactGroupsObject:(ContactGroup *)value;
- (void)removeContactGroupsObject:(ContactGroup *)value;
- (void)addContactGroups:(NSSet *)values;
- (void)removeContactGroups:(NSSet *)values;

@end
