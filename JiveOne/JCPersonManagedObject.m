//
//  Person.m
//  JiveOne
//
//  Created by Robert Barclay on 12/10/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCPersonManagedObject.h"
#import "JCPhoneNumberDataSourceUtils.h"
#import "NSManagedObject+Additions.h"

NSString *const kJCPersonT9AttributeKey     = @"t9";
NSString *const kJCPersonNameAttributeKey   = @"name";

@implementation JCPersonManagedObject

-(void)willSave
{
    if (![self isDeleted])
    {
        // generates the t9 representation of the name of the number.
        NSString *name = self.firstNameFirstName;
        if(name) {
            NSString *t9 = [JCPhoneNumberDataSourceUtils t9StringForString:name];
            [self setPrimitiveValue:name forKey:kJCPersonNameAttributeKey];
            [self setPrimitiveValue:t9 forKey:kJCPersonT9AttributeKey];
        }
    }
    [super willSave];
}

#pragma mark - Attributes -

@dynamic name;
@dynamic firstName;
@dynamic lastName;
@dynamic t9;

#pragma mark - Transient Protocol Methods -

-(NSString *)middleName
{
    return nil;  // We do not store, but is defined in protocol
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
    return nil; // We do not store, but is defined in protocol
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
    NSString *firstInitial = self.firstInitial;
    NSString *lastInitial = self.lastInitial;
    if (firstInitial && lastInitial) {
        return [NSString stringWithFormat:@"%@%@", firstInitial, lastInitial];
    }
    return lastInitial;
}

-(NSString *)firstNameFirstName
{
    NSString *firstName = self.firstName;
    NSString *lastName = self.lastName;
    if (firstName && lastName) {
        return [NSString stringWithFormat:@"%@ %@", firstName, lastName];
    }
    return firstName;
}

-(NSString *)lastNameFirstName
{
    return [NSString stringWithFormat:@"%@, %@", self.lastName, self.firstName];
}

#pragma mark - JCPhoneNumberDataSource Protocol -

-(NSString *)titleText
{
    return self.name;
}

-(NSString *)detailText
{
    return self.formattedNumber;
}

-(NSString *)name
{
    return self.firstNameFirstName;
}

-(NSString *)number
{
    return nil;
}

-(NSString *)dialableNumber
{
    return [JCPhoneNumberDataSourceUtils dialableStringForPhoneNumber:self];
}

-(NSString *)formattedNumber
{
    return [JCPhoneNumberDataSourceUtils formattedPhoneNumberForPhoneNumber:self];
}

-(NSAttributedString *)titleTextWithKeyword:(NSString *)keyword font:(UIFont *)font color:(UIColor *)color
{
    return [JCPhoneNumberDataSourceUtils titleTextWithKeyword:keyword
                                                         font:font
                                                        color:color
                                                  phoneNumber:self];
}

-(NSAttributedString *)detailTextWithKeyword:(NSString *)keyword font:(UIFont *)font color:(UIColor *)color
{
    return [JCPhoneNumberDataSourceUtils detailTextWithKeyword:keyword
                                                          font:font
                                                         color:color
                                                   phoneNumber:self];
}

-(BOOL)containsKeyword:(NSString *)keyword
{
    return [JCPhoneNumberDataSourceUtils phoneNumber:self
                                     containsKeyword:keyword];
}

-(BOOL)containsT9Keyword:(NSString *)keyword
{
    return [JCPhoneNumberDataSourceUtils phoneNumber:self
                                   containsT9Keyword:keyword];
}

-(BOOL)isEqualToPhoneNumber:(id<JCPhoneNumberDataSource>)phoneNumber
{
    return [JCPhoneNumberDataSourceUtils phoneNumber:self isEqualToPhoneNumber:phoneNumber];
}


@end
