//
//  JCAddressBookNumber.m
//  JiveOne
//
//  Created by Robert Barclay on 2/18/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

@import AddressBook;

#import "JCAddressBookNumber.h"
#import "NSString+Additions.h"
#import "PhoneNumber.h"

@implementation JCAddressBookNumber

+ (NSArray *)addressBookNumbersForRecordRef:(ABRecordRef)recordRef
{
    NSMutableArray *phoneNumbers = [NSMutableArray array];
    ABMultiValueRef phones = ABRecordCopyValue(recordRef, kABPersonPhoneProperty);
    for (CFIndex i=0; i < ABMultiValueGetCount(phones); i++) {
        JCAddressBookNumber *phoneNumber = [self addressBookNumberFromMultValueRef:phones atIndex:i record:recordRef];
        [phoneNumbers addObject:phoneNumber];
    }
    return  phoneNumbers;
}

+ (JCAddressBookNumber *)addressBookNumberForRecordRef:(ABRecordRef)recordRef withIdentifier:(ABMultiValueIdentifier)identifier;
{
    JCAddressBookNumber *phoneNumber = nil;
    ABMultiValueRef phones = ABRecordCopyValue(recordRef, kABPersonPhoneProperty);
    if (phones && ABMultiValueGetCount(phones) > 0)
    {
        CFIndex index = 0;
        if (identifier != kABMultiValueInvalidIdentifier) {
            index = ABMultiValueGetIndexForIdentifier(phones, identifier);
        }
        phoneNumber = [self addressBookNumberFromMultValueRef:phones atIndex:index record:recordRef];
        CFRelease(phones);
    }
    return phoneNumber;
}

-(instancetype)initWithNumber:(NSString *)number type:(NSString *)type identifier:(NSInteger)identifier record:(ABRecordRef)record
{
    self = [super initWithNumber:number record:record];
    if (self) {
        _type = type;
        _identifer = identifier;
    }
    return self;
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"%@ %@: %@", self.name, self.type, self.number];
}

#pragma mark - Super Overrides -

-(NSString *)detailText
{
    return [NSString stringWithFormat:@"%@: %@", self.type, super.detailText];
}

#pragma mark - Private -

+ (JCAddressBookNumber *)addressBookNumberFromMultValueRef:(ABMultiValueRef)phones atIndex:(CFIndex)index record:(ABRecordRef)record
{
    NSInteger identifer = ABMultiValueGetIdentifierAtIndex(phones, index);
    CFStringRef phoneNumberRef = ABMultiValueCopyValueAtIndex(phones, index);
    CFStringRef locLabel = ABMultiValueCopyLabelAtIndex(phones, index);
    NSString *type, *number;
    
    if (phoneNumberRef) {
        number = (__bridge NSString *)phoneNumberRef;
        CFRelease(phoneNumberRef);
    }
    if (locLabel) {
        type = (__bridge NSString *)ABAddressBookCopyLocalizedLabel(locLabel);
        CFRelease(locLabel);
    }
    return [[JCAddressBookNumber alloc] initWithNumber:number type:type identifier:identifer record:record];
}

@end
