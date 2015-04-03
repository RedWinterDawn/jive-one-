//
//  JCAddressBookNumber.m
//  JiveOne
//
//  Created by Robert Barclay on 2/18/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCAddressBookNumber.h"
#import "NSString+Additions.h"

@interface JCAddressBookNumber ()

@property (nonatomic, readonly) NSLocale *locale;

@end

@implementation JCAddressBookNumber

-(BOOL)containsKeyword:(NSString *)keyword
{
    NSLocale *locale = self.locale;
    NSString *localizedKeyword = [keyword lowercaseStringWithLocale:locale];
    
    if (localizedKeyword.isNumeric) {
        NSString *string = self.number.numericStringValue;
        if ([string respondsToSelector:@selector(containsString:)]) {
            if ([string containsString:localizedKeyword]) {
                return YES;
            }
        }
        else if ([string rangeOfString:localizedKeyword].location != NSNotFound) {
            return YES;
        }
        
        //TODO : T9 Match with the name.
    }
    
    NSString *fullName = [self.person.name lowercaseStringWithLocale:locale];
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

@synthesize number = _number;

-(NSLocale *)locale
{
    // Makes the startup of this singleton thread safe.
    static NSLocale *locale = nil;
    static dispatch_once_t pred;        // Lock
    dispatch_once(&pred, ^{             // This code is called at most once per app
        NSString *localization = [NSBundle mainBundle].preferredLocalizations.firstObject;
        locale = [[NSLocale alloc] initWithLocaleIdentifier:localization];
    });
    return locale;
}

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

-(NSAttributedString *)detailTextWithKeyword:(NSString *)keyword font:(UIFont *)font color:(UIColor *)color{
    
    NSMutableAttributedString *attributedNumberText = [self.number formattedPhoneNumberWithKeyword:keyword font:font color:color];
    NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                           font, NSFontAttributeName,
                           color, NSForegroundColorAttributeName, nil];
    
    NSAttributedString *typeString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@: ", self.type] attributes:attrs];
    [attributedNumberText insertAttributedString:typeString atIndex:0];
    return attributedNumberText;
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"%@ %@: %@", self.name, self.type, self.number];
}

@end
