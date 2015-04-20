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

@synthesize number = _number;

#pragma mark - Protocol Getters -

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

-(NSString *)lastName
{
    return self.person.lastName;
}

-(NSString *)firstInitial
{
    return self.person.firstInitial;
}

-(NSString *)lastInitial
{
    return self.person.lastInitial;
}

-(NSString *)lastNameFirstName
{
    return self.person.lastNameFirstName;
}

-(NSString *)firstNameFirstName
{
    return self.person.firstNameFirstName;
}

-(NSString *)detailText
{
    return [NSString stringWithFormat:@"%@: %@", self.type, self.number];
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"%@ %@: %@", self.name, self.type, self.number];
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

@end
