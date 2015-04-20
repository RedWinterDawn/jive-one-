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
    return [self getRecordValueForPropertyId:kABPersonFirstNameProperty];
}

-(NSString *)lastName
{
    return [self getRecordValueForPropertyId:kABPersonLastNameProperty];
}

-(NSString *)middleName
{
    return [self getRecordValueForPropertyId:kABPersonMiddleNameProperty];
}

#pragma mark Name Composites

-(NSString *)name
{
    return (__bridge_transfer NSString *)ABRecordCopyCompositeName(_person);
}

-(NSString *)firstNameFirstName
{
    return [self getRecordValueForPropertyId:kABPersonCompositeNameFormatFirstNameFirst];
}

-(NSString *)lastNameFirstName
{
    return [self getRecordValueForPropertyId:kABPersonCompositeNameFormatLastNameFirst];
}

-(NSString *)number
{
    JCAddressBookNumber *firstNumber = self.phoneNumbers.firstObject;
    return firstNumber.number;
}

-(NSArray *)phoneNumbers
{
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

#pragma mark - ABAddressBook Convience Methods -

- (NSString *)getRecordValueForPropertyId:(ABPropertyID)propertyId
{
    CFStringRef value = ABRecordCopyValue(_person, propertyId);
    NSString *string = [NSString stringWithString:(__bridge NSString *)(value)];
    CFRelease(value);
    return string;
}

- (NSNumber *)copyRecordValueAsNumber:(ABRecordRef)ref propertyId:(ABPropertyID)propertyId
{
    CFNumberRef value = ABRecordCopyValue(ref, propertyId);
    NSNumber *number = ((__bridge NSNumber *)value).copy;
    CFRelease(value);
    return number;
}

- (NSString *) copyMultiValueLabelAtIndex:(ABMultiValueRef)phones index:(CFIndex)index
{
    CFStringRef value = ABMultiValueCopyLabelAtIndex(phones, index);
    NSString *string = [NSString stringWithString:(__bridge NSString *)(value)];
    CFRelease(value);
    return string;
}

- (NSString *) copyMultiValueValueAtIndex:(ABMultiValueRef)phones index:(CFIndex)index
{
    CFStringRef value = ABMultiValueCopyValueAtIndex(phones, index);
    NSString *string = [NSString stringWithString:(__bridge NSString *)(value)];
    CFRelease(value);
    return string;
}



@end
