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
}

@end

@implementation JCAddressBookPerson

-(instancetype)initWithABRecordRef:(ABRecordRef)recordRef
{
    self = [super init];
    if (self) {
        _person = recordRef;
        CFRetain(_person);
        
        _t9 = self.name.t9;
    }
    return self;
}

-(void)dealloc {
    CFRelease(_person);
}

-(BOOL)containsKeyword:(NSString *)keyword
{
    
    
    
    
    
    
    
    
    
    return NO;
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

//-(NSString *)t9
//{
//    return self.name.t9;
//}

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

-(NSString *)detailText
{
    return self.name;
}

-(NSString *)number
{
    JCAddressBookNumber *firstNumber = self.phoneNumbers.firstObject;
    return firstNumber.number;
}

-(NSArray *)phoneNumbers {
    NSMutableArray *phoneNumbers = [NSMutableArray array];
    ABMultiValueRef phones = ABRecordCopyValue(_person, kABPersonPhoneProperty);
    for (CFIndex i=0; i < ABMultiValueGetCount(phones); i++) {
        CFStringRef phoneNumberRef = ABMultiValueCopyValueAtIndex(phones, i);
        CFStringRef locLabel = ABMultiValueCopyLabelAtIndex(phones, i);
        
        JCAddressBookNumber *number = [JCAddressBookNumber new];
        number.person = self;
        if (phoneNumberRef) {
            number.number = (__bridge NSString *)phoneNumberRef;
            CFRelease(phoneNumberRef);
        }
        
        if (locLabel) {
            number.type = (__bridge NSString *)ABAddressBookCopyLocalizedLabel(locLabel);
            CFRelease(locLabel);
        }
        
        [phoneNumbers addObject:number];
    }
    return  phoneNumbers;
}

-(BOOL)hasNumber:(NSString *)string
{
    NSArray *numbers = self.phoneNumbers;
    for (JCAddressBookNumber *number in numbers) {
        NSString *phoneNumber = number.number.numericStringValue;
        if ([string.numericStringValue containsString:phoneNumber] ) {
            return YES;
        }
    }
    return NO;
}

-(NSAttributedString *)detailTextWithKeyword:(NSString *)keyword font:(UIFont *)font color:(UIColor *)color
{
    return nil;
}

#pragma mark - ABAddressBook Convience Methods -

+ (NSString *)copyRecordValueAsString:(ABRecordRef)ref propertyId:(ABPropertyID)propertyId
{
    CFStringRef value = ABRecordCopyValue(ref, propertyId);
    NSString *string = [NSString stringWithString:(__bridge NSString *)(value)];
    CFRelease(value);
    return string;
}

+ (NSNumber *)copyRecordValueAsNumber:(ABRecordRef)ref propertyId:(ABPropertyID)propertyId
{
    CFNumberRef value = ABRecordCopyValue(ref, propertyId);
    NSNumber *number = ((__bridge NSNumber *)value).copy;
    CFRelease(value);
    return number;
}

+ (NSInteger)recordGetRecordID:(ABRecordRef)source
{
    return ABRecordGetRecordID(source);
}

+ (NSInteger)multiValueGetCount:(ABMultiValueRef)phones
{
    return ABMultiValueGetCount(phones);
}

+ (NSString *) copyMultiValueLabelAtIndex:(ABMultiValueRef)phones index:(CFIndex)index
{
    CFStringRef value = ABMultiValueCopyLabelAtIndex(phones, index);
    NSString *string = [NSString stringWithString:(__bridge NSString *)(value)];
    CFRelease(value);
    return string;
}

+ (NSString *) copyMultiValueValueAtIndex:(ABMultiValueRef)phones index:(CFIndex)index
{
    CFStringRef value = ABMultiValueCopyValueAtIndex(phones, index);
    NSString *string = [NSString stringWithString:(__bridge NSString *)(value)];
    CFRelease(value);
    return string;
}



@end
