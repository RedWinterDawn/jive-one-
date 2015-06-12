//
//  Contact.h
//  JiveOne
//
//  Created by Robert Barclay on 6/5/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCPersonManagedObject.h"

@class PhoneNumber;
@class User;

@interface Contact : JCPersonManagedObject

// Attributes
@property (nonatomic, retain) NSString *etag;
@property (nonatomic, retain) NSString *data;

// Relationships
@property (nonatomic, retain) User *user;
@property (nonatomic, retain) NSSet *phoneNumbers;
@property (nonatomic, retain) NSSet *addresses;
@property (nonatomic, retain) NSSet *info;

@end

@interface Contact (CoreDataGeneratedAccessors)

- (void)addPhoneNumbersObject:(PhoneNumber *)value;
- (void)removePhoneNumbersObject:(PhoneNumber *)value;
- (void)addPhoneNumbers:(NSSet *)values;
- (void)removePhoneNumbers:(NSSet *)values;

- (void)addAddressesObject:(PhoneNumber *)value;
- (void)removeAddressesObject:(PhoneNumber *)value;
- (void)addAddresses:(NSSet *)values;
- (void)removeAddresses:(NSSet *)values;

- (void)addInfoObject:(PhoneNumber *)value;
- (void)removeInfoObject:(PhoneNumber *)value;
- (void)addInfo:(NSSet *)values;
- (void)removeInfo:(NSSet *)values;

@end
