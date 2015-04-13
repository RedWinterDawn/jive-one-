//
//  JCAddressBookEntity.m
//  JiveOne
//
//  Created by Robert Barclay on 4/9/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCAddressBookEntity.h"
#import "NSString+Additions.h"

@implementation JCAddressBookEntity

#pragma mark - Getters -

-(NSString *)titleText
{
    return self.name;
}

-(NSString *)detailText
{
    return self.number.dialableString.formattedPhoneNumber;
}

@synthesize name = _name;
@synthesize number = _number;

-(NSString *)t9
{
    return self.name.t9;
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
    return [self.name formattedStringWithT9Keyword:keyword font:font color:color];
}

-(NSAttributedString *)detailTextWithKeyword:(NSString *)keyword font:(UIFont *)font color:(UIColor *)color{
    
    return [self.number formattedPhoneNumberWithNumericKeyword:keyword font:font color:color];
}

@end
