//
//  JCAddressBookPerson.m
//  JiveOne
//
//  Created by Robert Barclay on 2/10/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCAddressBookPerson.h"
#import "NSString+Additions.h"
#import "JCAddressBook.h"
#import "JCAddressBookNumber.h"

@interface JCAddressBookPerson () {
    ABRecordRef _person;
    NSArray *_phoneNumbers;
}

@end

@implementation JCAddressBookPerson

+(instancetype)addressBookPersonWithABRecordRef:(ABRecordRef)recordRef
{
    NSArray *phoneNumbers = [JCAddressBookNumber addressBookNumbersForRecordRef:recordRef];
    JCAddressBookNumber *number = phoneNumbers.firstObject;
    return [[JCAddressBookPerson alloc] initWithNumber:number.dialableNumber
                                        phoneNumbers:phoneNumbers
                                              person:recordRef];
}

-(instancetype)initWithNumber:(NSString *)number phoneNumbers:(NSArray *)phoneNumbers person:(ABRecordRef)person
{
    self = [super initWithNumber:number record:person];
    if (self) {
        _phoneNumbers = phoneNumbers;
    }
    return self;
}

-(JCAddressBookNumber *)addressBookNumberForIdentifier:(ABMultiValueIdentifier)identifier
{
    for (JCAddressBookNumber *phoneNumber in self.phoneNumbers) {
        if(phoneNumber.identifer == identifier) {
            return phoneNumber;
        }
    }
    return nil;
}

@end
