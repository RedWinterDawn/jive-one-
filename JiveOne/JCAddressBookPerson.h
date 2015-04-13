//
//  JCAddressBookPerson.h
//  JiveOne
//
//  Created by Robert Barclay on 2/10/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

@import AddressBook;

#import "JCPhoneNumber.h"
#import "JCPersonDataSource.h"
#import "JCAddressBookNumber.h"

@interface JCAddressBookPerson : JCPhoneNumber <JCPersonDataSource>

-(instancetype)initWithABRecordRef:(ABRecordRef)recordRef;

// Identifers
@property (nonatomic, readonly) NSInteger recordId;
@property (nonatomic, readonly) NSString *personId;
@property (nonatomic, readonly) NSString *personHash;

@property (nonatomic, readonly) NSArray *phoneNumbers;

-(JCAddressBookNumber *)addressBookNumberForIdentifier:(ABMultiValueIdentifier)identifier;

-(BOOL)hasNumber:(NSString *)string;

@end
