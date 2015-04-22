//
//  JCAddressBookPerson.h
//  JiveOne
//
//  Created by Robert Barclay on 2/10/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

@import AddressBook;

#import "JCAddressBookEntity.h"
#import "JCAddressBookNumber.h"

@interface JCAddressBookPerson : JCAddressBookEntity

+ (instancetype)addressBookPersonWithABRecordRef:(ABRecordRef)recordRef;

@property (nonatomic, readonly) NSArray *phoneNumbers;

-(JCAddressBookNumber *)addressBookNumberForIdentifier:(NSInteger)identifier;

@end
