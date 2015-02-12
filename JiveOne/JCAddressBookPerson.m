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

@interface JCAddressBookPerson () {
    ABRecordRef _person;
}

@end

@implementation JCAddressBookPerson

-(instancetype)initWithABRecordRef:(ABRecordRef)recordRef
{
    self = [super init];
    if (self) {
        _person = recordRef;
        CFRetain(_person);
    }
    return self;
}

-(void)dealloc {
    CFRelease(_person);
}

#pragma mark - Getters -

-(NSInteger)recordId
{
    return ABRecordGetRecordID(_person);
}

-(NSString *)personId
{
    return [NSString stringWithFormat:@"%li", (long)self.recordId];
}

-(NSString *)personHash
{
    return [self.firstNameFirstName MD5Hash];
}

#pragma mark Name Elements

-(NSString *)firstName
{
    return (__bridge_transfer NSString *)ABRecordCopyValue(_person, kABPersonFirstNameProperty);
}

-(NSString *)lastName
{
    return (__bridge_transfer NSString *)ABRecordCopyValue(_person, kABPersonLastNameProperty);
}

-(NSString *)middleName
{
    return (__bridge_transfer NSString *)ABRecordCopyValue(_person, kABPersonMiddleNameProperty);
}

#pragma mark Name Composites

-(NSString *)name
{
    return (__bridge_transfer NSString *)ABRecordCopyCompositeName(_person);
}

-(NSString *)firstNameFirstName
{
    return (__bridge_transfer NSString *)ABRecordCopyValue(_person, kABPersonCompositeNameFormatFirstNameFirst);
}

-(NSString *)lastNameFirstName
{
    return (__bridge_transfer NSString *)ABRecordCopyValue(_person, kABPersonCompositeNameFormatLastNameFirst);
}

#pragma mark Name Initials

-(NSString *)firstInitial
{
    NSString *firstName = self.firstName;
    if (firstName.length > 0) {
        return [firstName substringToIndex:1].uppercaseString;
    }
    return nil;
}

-(NSString *)middleInitial
{
    NSString *middleName = self.middleName;
    if (middleName.length > 0) {
        return [middleName substringToIndex:1].uppercaseString;
    }
    return nil;
}

-(NSString *)lastInitial
{
    NSString *lastName = self.lastName;
    if (lastName.length > 0) {
        return [lastName substringToIndex:1].uppercaseString;
    }
    return nil;
}

-(NSString *)initials
{
    NSString *middleInitial = self.middleInitial;
    NSString *firstInitial = self.firstInitial;
    NSString *lastInitial = self.lastInitial;
    if (firstInitial && middleInitial && lastInitial) {
        return [NSString stringWithFormat:@"%@%@%@", firstInitial, middleInitial, lastInitial];
    } else if (firstInitial && lastInitial) {
        return [NSString stringWithFormat:@"%@%@", firstInitial, lastInitial];
    }
    return lastInitial;
}

@end
