//
//  JCAddressBookEntity.m
//  JiveOne
//
//  Created by Robert Barclay on 4/15/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCAddressBookEntity.h"

@interface JCAddressBookEntity ()
{
    ABRecordRef _record;
    
    NSString *_firstName;
    NSString *_middleName;
    NSString *_lastName;
}

@end

@implementation JCAddressBookEntity

- (instancetype)initWithNumber:(NSString *)number record:(ABRecordRef)record
{
    NSString *name = (__bridge_transfer NSString *)ABRecordCopyCompositeName(record);
    self = [super initWithName:name number:number];
    if (self) {
        _record       = record;
        CFRetain(record);
        
        _recordId     = ABRecordGetRecordID(record);
        _personHash   = name.MD5Hash;
        
        _firstName    = [self getRecordValueForPropertyId:kABPersonFirstNameProperty];
        _middleName   = [self getRecordValueForPropertyId:kABPersonMiddleNameProperty];
        _lastName     = [self getRecordValueForPropertyId:kABPersonLastNameProperty];
    }
    return self;
}

-(void)dealloc {
    if (_record) {
        CFRelease(_record);
    }
}

#pragma mark - Getters -
#pragma mark JCPersonDataSource

@synthesize firstName = _firstName;
@synthesize middleName = _middleName;
@synthesize lastName = _lastName;

-(NSString *)firstNameFirstName
{
    return [self getRecordValueForPropertyId:kABPersonCompositeNameFormatFirstNameFirst];
}

-(NSString *)lastNameFirstName
{
    return [self getRecordValueForPropertyId:kABPersonCompositeNameFormatLastNameFirst];
}

-(NSString *)firstInitial
{
    NSString *firstName = self.firstName;
    if (firstName.length > 0) {
        return [[firstName substringToIndex:1] uppercaseStringWithLocale:firstName.locale];
    }
    return nil;
}

-(NSString *)middleInitial
{
    NSString *middleName = self.middleName;
    if (middleName.length > 0) {
        return [[middleName substringToIndex:1] uppercaseStringWithLocale:middleName.locale];
    }
    return nil;
}

-(NSString *)lastInitial
{
    NSString *lastName = self.lastName;
    if (lastName.length > 0) {
        return [[lastName substringToIndex:1] uppercaseStringWithLocale:lastName.locale];
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

#pragma mark - Private -

- (NSString *)getRecordValueForPropertyId:(ABPropertyID)propertyId
{
    CFStringRef value = ABRecordCopyValue(_record, propertyId);
    if (value) {
        NSString *string = [NSString stringWithString:(__bridge NSString *)(value)];
        CFRelease(value);
        return string;
    }
    return nil;
}

- (NSNumber *)copyRecordValueAsNumber:(ABRecordRef)ref propertyId:(ABPropertyID)propertyId
{
    CFNumberRef value = ABRecordCopyValue(ref, propertyId);
    if (value) {
        NSNumber *number = ((__bridge NSNumber *)value).copy;
        CFRelease(value);
        return number;
    }
    return nil;
}

- (NSString *) copyMultiValueLabelAtIndex:(ABMultiValueRef)phones index:(CFIndex)index
{
    CFStringRef value = ABMultiValueCopyLabelAtIndex(phones, index);
    if (value) {
        NSString *string = [NSString stringWithString:(__bridge NSString *)(value)];
        CFRelease(value);
        return string;
    }
    return nil;
}

- (NSString *) copyMultiValueValueAtIndex:(ABMultiValueRef)phones index:(CFIndex)index
{
    CFStringRef value = ABMultiValueCopyValueAtIndex(phones, index);
    if (value) {
        NSString *string = [NSString stringWithString:(__bridge NSString *)(value)];
        CFRelease(value);
        return string;
    }
    return nil;
}

@end
