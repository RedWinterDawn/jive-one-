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

@dynamic name;
@dynamic firstName;
@dynamic lastName;

-(NSString *)middleName
{
    return nil;
}

-(NSString *)detailText
{
    return nil;
}

-(NSString *)number
{
    return nil;
}

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

@end
