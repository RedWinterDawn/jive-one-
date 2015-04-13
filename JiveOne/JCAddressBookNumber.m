//
//  JCAddressBookNumber.m
//  JiveOne
//
//  Created by Robert Barclay on 2/18/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCAddressBookNumber.h"
#import "JCAddressBookPerson.h"
#import "NSString+Additions.h"

@implementation JCAddressBookNumber

@synthesize number;

-(NSString *)description
{
    return [NSString stringWithFormat:@"%@ %@: %@", self.name, self.type, self.number];
}

#pragma mark - Super Overrides -

-(NSString *)detailText
{
    return [NSString stringWithFormat:@"%@: %@", self.type, self.number];
}

-(NSAttributedString *)detailTextWithKeyword:(NSString *)keyword font:(UIFont *)font color:(UIColor *)color{
    
    NSAttributedString *attributedString = [super detailTextWithKeyword:keyword font:font color:color];
    NSMutableAttributedString *attributedNumberText = [[NSMutableAttributedString alloc] initWithAttributedString:attributedString];
    NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                           font, NSFontAttributeName,
                           color, NSForegroundColorAttributeName, nil];
    
    NSAttributedString *typeString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@: ", self.type] attributes:attrs];
    [attributedNumberText insertAttributedString:typeString atIndex:0];
    return attributedNumberText;
}

#pragma mark - JCPersonDataSource Protocol Getters -

//  Since we maintain a pointer to the parent person, we just forward all properties relating to the
//  person from the parent person.

-(NSString *)name
{
    return self.person.name;
}

-(NSString *)firstName
{
    return self.person.firstName;
}

-(NSString *)middleName
{
    return self.person.middleName;
}

-(NSString *)lastName
{
    return self.person.lastName;
}

-(NSString *)firstInitial
{
    return self.person.firstInitial;
}

-(NSString *)middleInitial
{
    return self.person.middleInitial;
}

-(NSString *)lastInitial
{
    return self.person.lastInitial;
}

-(NSString *)initials
{
    return self.person.initials;
}

-(NSString *)lastNameFirstName
{
    return self.person.lastNameFirstName;
}

-(NSString *)firstNameFirstName
{
    return self.person.firstNameFirstName;
}

@end
