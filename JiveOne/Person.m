//
//  Person.m
//  JiveOne
//
//  Created by Robert Barclay on 12/10/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "Person.h"

#import "NSManagedObject+Additions.h"

NSString *const kPersonNameAttributeKey = @"name";
NSString *const kPersonFirstNameAttributeKey = @"firstName";
NSString *const kPersonLastNameAttributeKey = @"lastName";
NSString *const kPersonT9AttributeKey = @"t9";

@implementation Person

#pragma mark - Attributes -

@dynamic name;
@dynamic firstName;
@dynamic lastName;
@dynamic t9;

-(NSString *)titleText
{
    return self.name;
}

-(NSString *)detailText
{
    NSString *number = self.number;
    if (!number) {
        return nil;
    }
    return number.formattedPhoneNumber;
}

-(NSString *)name
{
    NSString *name = [self primitiveValueForKey:kPersonNameAttributeKey];
    if (name) {
        return name;
    }
    
    NSString *firstName = [self primitiveValueForKey:kPersonFirstNameAttributeKey];
    NSString *lastName = [self primitiveValueForKey:kPersonLastNameAttributeKey];
    if (firstName && lastName) {
        return [NSString stringWithFormat:@"%@ %@", firstName, lastName];
    }
    else if (lastName) {
        return lastName;
    }
    return nil;
}

-(NSString *)firstName
{
    NSString *firstName = [self primitiveValueForKey:kPersonFirstNameAttributeKey];
    if (firstName) {
        return firstName;
    }
    
    NSString *name = [self primitiveValueForKey:kPersonNameAttributeKey];
    if (name) {
        NSArray *components = [name componentsSeparatedByString:@" "];
        if (components.count > 1) {
            return components.firstObject;
        }
    }
    return nil;
}

-(NSString *)lastName
{
    NSString *lastName = [self primitiveValueForKey:kPersonLastNameAttributeKey];
    if (lastName) {
        return lastName;
    }
    
    NSString *name = [self primitiveValueForKey:kPersonNameAttributeKey];
    NSArray *components = [name componentsSeparatedByString:@" "];
    if (components.count > 1) {
        return components.lastObject;
    }
    return name;
}

-(NSString *)t9
{
    NSString *t9 = [self primitiveValueForKey:kPersonT9AttributeKey];
    if(t9) {
        return t9;
    }
    
    return self.name.t9;
}

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
    
    NSString *lastName = self.lastName;
    if (lastName.length > 0) {
        return [[lastName substringToIndex:1] uppercaseStringWithLocale:lastName.locale];
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

-(NSString *)number
{
    return nil;
}

#pragma mark - Methods -

-(BOOL)containsKeyword:(NSString *)keyword
{
    NSString *localizedKeyword = [keyword lowercaseStringWithLocale:keyword.locale];
    
    if (localizedKeyword.isNumeric) {
        NSString *string = self.number.numericStringValue;
        if ([string rangeOfString:localizedKeyword].location != NSNotFound) {
            return YES;
        }
        if ([self containsT9Keyword:keyword]) {
            return YES;
        }
    }
    
    NSString *name = self.name;
    NSString *fullName = [name lowercaseStringWithLocale:name.locale];
    if ([fullName respondsToSelector:@selector(containsString:)]) {
        if ([fullName containsString:localizedKeyword]) {
            return YES;
        }
    }
    else if ([fullName rangeOfString:localizedKeyword].location != NSNotFound) {
        return YES;
    }
    
    return NO;
}

-(BOOL)containsT9Keyword:(NSString *)keyword
{
    NSString *t9 = self.t9;
    if ([t9 hasPrefix:keyword]) {
        return YES;
    }
    return NO;
}

-(NSAttributedString *)titleTextWithKeyword:(NSString *)keyword font:(UIFont *)font color:(UIColor *)color
{
    // if no name, return nil.
    NSString *name = self.name;
    if(!name) {
        return nil;
    }
    
    // T9 keyword formating
    if (keyword.isNumeric) {
        return [self.name formattedStringWithT9Keyword:keyword font:font color:color];
    }
    
    // Return formatted string with no alterations.
    NSDictionary *attrs = @{NSFontAttributeName: font, NSForegroundColorAttributeName: color};
    return [[NSAttributedString alloc] initWithString:name attributes:attrs];
}

-(NSAttributedString *)detailTextWithKeyword:(NSString *)keyword font:(UIFont *)font color:(UIColor *)color
{
    NSString *number = self.number;
    if (!number) {
        return nil;
    }
    
    return [number formattedPhoneNumberWithNumericKeyword:keyword font:font color:color];
}





@end
