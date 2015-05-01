//
//  JCMultiPersonPhoneNumber.m
//  JiveOne
//
//  Created by Robert Barclay on 4/13/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCMultiPersonPhoneNumber.h"
#import "JCPersonDataSource.h"

NSString *const kMultiPersonPhoneNumberFormattingTwoPeople = @"%@, %@";
NSString *const kMultiPersonPhoneNumberFormattingThreePlusPeople = @"%@,...+%li";

@implementation JCMultiPersonPhoneNumber

+(instancetype)multiPersonPhoneNumberWithPhoneNumbers:(NSArray *)phoneNumbers
{
    NSString *name, *number;
    if (phoneNumbers.count > 0)
    {
        id<JCPhoneNumberDataSource> firstPhoneNumber = phoneNumbers.firstObject;
        if (![firstPhoneNumber conformsToProtocol:@protocol(JCPhoneNumberDataSource)]) {
            [NSException exceptionWithName:NSInvalidArgumentException reason:@"object does not conform to the JCPhoneNumberDataSource Protocol" userInfo:nil];
        }
        
        number = firstPhoneNumber.dialableNumber;
        [self validatePhoneNumbersArray:phoneNumbers number:number];
        name = [self nameForNumbers:phoneNumbers];
    }
    return [[[self class] alloc] initWithName:name number:number phoneNumbers:phoneNumbers];
}

#pragma mark - Private -

+(NSString *)nameFromPhoneNumber:(id<JCPhoneNumberDataSource>)phoneNumber
{
    if ([phoneNumber conformsToProtocol:@protocol(JCPersonDataSource) ]) {
        return ((id<JCPersonDataSource>)phoneNumber).firstName;
    }
    return phoneNumber.name;
}

+(void)validatePhoneNumbersArray:(NSArray *)phoneNumbers number:(NSString *)number
{
    for (id<JCPhoneNumberDataSource> phoneNumber in phoneNumbers) {
        if (![phoneNumber conformsToProtocol:@protocol(JCPhoneNumberDataSource)]) {
            [NSException exceptionWithName:NSInvalidArgumentException reason:@"object does not conform to the JCPhoneNumberDataSource Protocol" userInfo:nil];
        }
        
        if (![phoneNumber.dialableNumber isEqualToString:number]) {
            [NSException exceptionWithName:NSInvalidArgumentException reason:@"object does not contain a matching phone number" userInfo:nil];
        }
    }
}

+(NSString *)nameForNumbers:(NSArray *)phoneNumbers
{
    id<JCPhoneNumberDataSource> phoneNumber = phoneNumbers.firstObject;
    NSString *firstName = [self nameFromPhoneNumber:phoneNumber];
    NSUInteger count = phoneNumbers.count;
    if (count == 1) {
        return firstName ? firstName : nil;
    }
    if (count == 2) {
        id<JCPhoneNumberDataSource> otherPhoneNumber = phoneNumbers.lastObject;
        NSString *lastName = [self nameFromPhoneNumber:otherPhoneNumber];
        if ([firstName isEqualToString:lastName] && [phoneNumber.name isEqualToString:otherPhoneNumber.name]) {
            return phoneNumber.name;
        }
        return lastName ? [NSString stringWithFormat:kMultiPersonPhoneNumberFormattingTwoPeople, firstName, lastName] : (firstName ? firstName : nil);
    }
    return firstName ? [NSString stringWithFormat:kMultiPersonPhoneNumberFormattingThreePlusPeople, firstName, (long)count-1] : nil;
}

-(instancetype)initWithName:(NSString *)name number:(NSString *)number phoneNumbers:(NSArray *)phoneNumbers
{
    self = [super initWithName:name number:number];
    if (self) {
        _phoneNumbers = phoneNumbers;
    }
    return self;
}

@end
