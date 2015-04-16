//
//  Person.m
//  JiveOne
//
//  Created by Robert Barclay on 12/10/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCPersonManagedObject.h"
#import "NSManagedObject+Additions.h"

NSString *const kPersonFirstNameAttributeKey = @"firstName";
NSString *const kPersonLastNameAttributeKey = @"lastName";

@implementation JCPersonManagedObject

-(void)willSave
{
    if (![self isDeleted])
    {
        NSString *name = self.name;
        if(name) {
            NSArray *components = [name componentsSeparatedByString:@" "];
            if (components.count > 1) {
                NSString *firstName = [self primitiveValueForKey:kPersonFirstNameAttributeKey];
                NSString *lastName = [self primitiveValueForKey:kPersonLastNameAttributeKey];
                if (!firstName) {
                    [self setPrimitiveValue:components.firstObject forKey:kPersonFirstNameAttributeKey];
                }
                if (!lastName) {
                    [self setPrimitiveValue:components.lastObject forKey:kPersonLastNameAttributeKey];
                }
            }
        }
    }
    [super willSave];
}

#pragma mark - Attributes -

@dynamic firstName;
@dynamic lastName;

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
    
    NSString *name = self.name;
    if (name.length > 0) {
        return [[name substringToIndex:1] uppercaseStringWithLocale:name.locale];
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
    
    NSString *name = self.name;
    if (name.length > 0) {
        return [[name substringToIndex:1] uppercaseStringWithLocale:name.locale];
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
    return self.name;
}

-(NSString *)lastNameFirstName
{
    return [NSString stringWithFormat:@"%@, %@", self.lastName, self.firstName];
}



@end
