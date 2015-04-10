//
//  JCNumber.m
//  JiveOne
//
//  Created by Robert Barclay on 4/9/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCPhoneNumber.h"

@implementation JCPhoneNumber

@synthesize name = _name;
@synthesize number = _number;

-(NSString *)titleText
{
    return self.name;
}

-(NSString *)detailText
{
    return self.number.formattedPhoneNumber;
}

-(NSString *)dialableNumber
{
    return self.number.dialableString;
}

-(NSString *)t9
{
    return self.number.t9;
}

-(NSAttributedString *)titleTextWithKeyword:(NSString *)keyword font:(UIFont *)font color:(UIColor *)color
{
    return [self.name formattedStringWithT9Keyword:keyword font:font color:color];
}

-(NSAttributedString *)detailTextWithKeyword:(NSString *)keyword font:(UIFont *)font color:(UIColor *)color
{
    return [self.number formattedPhoneNumberWithNumericKeyword:keyword font:font color:color];
}

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

@end
