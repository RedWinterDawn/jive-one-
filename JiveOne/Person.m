//
//  Person.m
//  JiveOne
//
//  Created by Robert Barclay on 12/10/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "Person.h"

#import "NSManagedObject+Additions.h"

NSString *const kPersonFirstNameAttributeKey = @"firstName";
NSString *const kPersonLastNameAttributeKey = @"lastName";

@implementation Person

#pragma mark - Attributes -

@dynamic name;
@dynamic firstName;
@dynamic lastName;

#pragma mark - Transient Protocol Methods -

-(NSString *)firstName
{
    NSString *firstName = [self primitiveValueForKey:kPersonFirstNameAttributeKey];
    if (firstName) {
        return firstName;
    }
    
    NSString *name = self.name;
    NSArray *components = [name componentsSeparatedByString:@" "];
    if (components.count > 1) {
        return components.firstObject;
    }
    return nil;
}

-(NSString *)middleName
{
    return nil;  // We do not store
}

-(NSString *)lastName
{
    NSString *lastName = [self primitiveValueForKey:kPersonLastNameAttributeKey];
    if (lastName) {
        return lastName;
    }
    
    NSString *name = self.name;
    NSArray *components = [name componentsSeparatedByString:@" "];
    if (components.count > 1) {
        return components.lastObject;
    }
    return name;
}

-(NSString *)firstInitial
{
    NSString *firstName = self.firstName;
    if (firstName.length > 0) {
        return [firstName substringToIndex:1].uppercaseString;
    }
    
    NSString *lastName = self.lastName;
    if (lastName.length > 0) {
        return [lastName substringToIndex:1].uppercaseString;
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

-(NSString *)number
{
    return nil;
}

#pragma mark - Public Methods -

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
    NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                           font, NSFontAttributeName,
                           color, NSForegroundColorAttributeName, nil];
    
    return [[NSAttributedString alloc] initWithString:name attributes:attrs];
}

-(NSString *)detailText
{
    NSString *number = self.number;
    if (!number) {
        return nil;
    }
    return number.formattedPhoneNumber;
}

-(NSAttributedString *)detailTextWithKeyword:(NSString *)keyword font:(UIFont *)font color:(UIColor *)color
{
    NSString *number = self.number;
    if (!number) {
        return nil;
    }
    
    return [number formattedPhoneNumberWithKeyword:keyword font:font color:color];
}





@end
