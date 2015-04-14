//
//  JCMultiPersonPhoneNumber.m
//  JiveOne
//
//  Created by Robert Barclay on 4/13/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCMultiPersonPhoneNumber.h"
#import "JCPersonDataSource.h"

@interface JCMultiPersonPhoneNumber ()

@end

@implementation JCMultiPersonPhoneNumber

NSString *const kMultiPersonPhoneNumberFormattingTwoPeople = @"%@, %@";
NSString *const kMultiPersonPhoneNumberFormattingThreePlusPeople = @"%@,...+%li";

-(instancetype)initWithPhoneNumbers:(NSArray *)phoneNumbers
{
    self = [super init];
    if (self)
    {
        if (phoneNumbers.count > 0)
        {
            id<JCPhoneNumberDataSource> object = phoneNumbers.firstObject;
            if (![object conformsToProtocol:@protocol(JCPhoneNumberDataSource)]) {
                [NSException exceptionWithName:NSInvalidArgumentException reason:@"object does not conform to the JCPhoneNumberDataSource Protocol" userInfo:nil];
            }
            
            // Data Validation. Only phone number data source objects with the same phone number can be added to the phone numbers.
            self.number = [object.number copy];
            
            NSString *name;
            NSUInteger count = phoneNumbers.count;
            for (id<JCPhoneNumberDataSource> phoneNumber in phoneNumbers) {
                if (![phoneNumber.number isEqualToString:self.number]) {
                    [NSException exceptionWithName:NSInvalidArgumentException reason:@"object does not conform to the JCPhoneNumberDataSource Protocol" userInfo:nil];
                }
                
                NSString *firstPhoneNumberName;
                if ([phoneNumber conformsToProtocol:@protocol(JCPersonDataSource) ]) {
                    id<JCPersonDataSource> person = (id<JCPersonDataSource>)phoneNumber;
                    firstPhoneNumberName = person.firstName;
                } else {
                    firstPhoneNumberName = phoneNumber.name;
                }
                
                if (count > 1)
                {
                    if (count == 2)
                    {
                        id<JCPhoneNumberDataSource> otherNumber = phoneNumbers.lastObject;
                        NSString *lastPhoneNumberName;
                        if ([otherNumber conformsToProtocol:@protocol(JCPersonDataSource) ]) {
                            id<JCPersonDataSource> person = (id<JCPersonDataSource>)otherNumber;
                            lastPhoneNumberName = person.firstName;
                        } else {
                            lastPhoneNumberName = otherNumber.name;
                        }
                        name = [NSString stringWithFormat:kMultiPersonPhoneNumberFormattingTwoPeople, firstPhoneNumberName, lastPhoneNumberName];
                    } else {
                        [NSString stringWithFormat:kMultiPersonPhoneNumberFormattingThreePlusPeople, firstPhoneNumberName, (long)count-1];
                    }
                } else {
                    name = phoneNumber.name;
                }
            }
            self.name = name;
            _phoneNumbers = phoneNumbers;
        }
    }
    return self;
}

@end
