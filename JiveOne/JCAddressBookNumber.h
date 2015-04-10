//
//  JCAddressBookNumber.h
//  JiveOne
//
//  Created by Robert Barclay on 2/18/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCPhoneNumber.h"
#import "JCPersonDataSource.h"

@class JCAddressBookPerson;

@interface JCAddressBookNumber : JCPhoneNumber <JCPersonDataSource>

// raw string as per the value stored in the ABAddressBook.
@property (nonatomic, strong) NSString *number;

// describes what type of number we are. obtained from the ABAddressBook.
@property (nonatomic, strong) NSString *type;

// pointer to parent person. We are a one-to-many child of a person.
@property (nonatomic, weak) JCAddressBookPerson *person;

@end
