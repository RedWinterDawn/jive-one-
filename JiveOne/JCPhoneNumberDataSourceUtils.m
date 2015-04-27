//
//  JCPhoneNumberDataSourceUtils.m
//  JiveOne
//
//  Created by Robert Barclay on 4/16/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCPhoneNumberDataSourceUtils.h"

#import <libPhoneNumber-iOS/NBPhoneNumberUtil.h>
#import <libPhoneNumber-iOS/NBAsYouTypeFormatter.h>

@implementation JCPhoneNumberDataSourceUtils

+(BOOL)phoneNumber:(id<JCPhoneNumberDataSource>)phoneNumber containsT9Keyword:(NSString *)keyword
{
    NSString *t9 = phoneNumber.t9;
    if (t9 && keyword && [t9 hasPrefix:keyword]) {
        return YES;
    }
    return NO;
}

+(BOOL)phoneNumber:(id<JCPhoneNumberDataSource>)phoneNumber containsKeyword:(NSString *)keyword
{
    NSString *localizedKeyword = [keyword lowercaseStringWithLocale:keyword.locale];
    if (localizedKeyword.isNumeric) {
        NSString *string = phoneNumber.number.numericStringValue;
        if ([string rangeOfString:localizedKeyword].location != NSNotFound) {
            return YES;
        }
        if ([self phoneNumber:phoneNumber containsT9Keyword:keyword]) {
            return YES;
        }
    }
    
    NSString *name = phoneNumber.name;
    NSString *fullName = [name lowercaseStringWithLocale:name.locale];
    if (fullName && [fullName rangeOfString:localizedKeyword].location != NSNotFound) {
        return YES;
    }
    return NO;
}

+(BOOL)phoneNumber:(id<JCPhoneNumberDataSource>)phoneNumber isEqual:(id)object
{
    if (![object conformsToProtocol:@protocol(JCPhoneNumberDataSource)]) {
        return FALSE;
    }
    
    id<JCPhoneNumberDataSource> otherPhoneNumber = (id<JCPhoneNumberDataSource>)object;
    if ([phoneNumber.name isEqualToString:otherPhoneNumber.name] && [phoneNumber.dialableNumber isEqualToString:otherPhoneNumber.dialableNumber]) {
        return TRUE;
    }
    return FALSE;
}

+(NSString *)t9StringForPhoneNumber:(id<JCPhoneNumberDataSource>)phoneNumber
{
    return [self t9StringForString:phoneNumber.name];
}

+(NSString *)t9StringForString:(NSString *)string
{
    if (!string) {
        return nil;
    }
    
    NSMutableString *t9 = [NSMutableString string];
    NSUInteger length = string.length;
    unichar buffer[length+1];
    [string getCharacters:buffer range:NSMakeRange(0, length)];
    for(int i = 0; i < length; i++)
    {
        NSString *character = [self getNumericCharFromAlphabeticString:[NSString stringWithFormat:@"%C", buffer[i]]];
        if (character)
            [t9 appendString:character];
    }
    
    // Return dial string if we can.
    if (t9.length > 0)
        return t9;
    return nil;
}

+(NSString *)dialableStringForPhoneNumber:(id<JCPhoneNumberDataSource>)phoneNumber
{
    NSCharacterSet *allowedCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"*+#0123456789"];
    return [[phoneNumber.number componentsSeparatedByCharactersInSet:[allowedCharacterSet invertedSet]] componentsJoinedByString:@""];
}

+(NSString *)formattedPhoneNumberForPhoneNumber:(id<JCPhoneNumberDataSource>)phoneNumber
{
    NSString *number = phoneNumber.dialableNumber;
    if (number.length < 5)
        return number;
    
    static NBPhoneNumberUtil *phoneNumberUtil;
    static dispatch_once_t pred;
    dispatch_once(&pred, ^{
        phoneNumberUtil = [NBPhoneNumberUtil new];
    });
    
    __autoreleasing NSError *error;
    NBPhoneNumber *phoneNumberObject = [phoneNumberUtil parse:number defaultRegion:@"US" error:&error];
    if (error)
        NSLog(@"%@", [error description]);
    return [phoneNumberUtil format:phoneNumberObject numberFormat:NBEPhoneNumberFormatNATIONAL error:&error];
}

+(NSAttributedString *)titleTextWithKeyword:(NSString *)keyword font:(UIFont *)font color:(UIColor *)color phoneNumber:(id<JCPhoneNumberDataSource>)phoneNumber
{
    NSString *name = phoneNumber.name;
    if (!name){
        return nil;
    }
    
    NSDictionary *attrs = @{ NSFontAttributeName: font, NSForegroundColorAttributeName: color };
    NSMutableAttributedString *attributedStringText = [[NSMutableAttributedString alloc] initWithString:name attributes:attrs];
    if (!keyword || !keyword.isNumeric) {
        return attributedStringText;
    }
    
    NSDictionary *boldAttrs = @{ NSFontAttributeName: [UIFont boldFontForFont:font], NSForegroundColorAttributeName: color };
    
    // Get buffer array of all characters in the string from self.
    NSUInteger len = name.length;
    unichar buffer[len +1];
    [name getCharacters:buffer range:NSMakeRange(0, len)];
    
    // Get buffer array of all characters in the keyword string.
    NSUInteger keywordLen = keyword.length;
    unichar keywordBuffer[keywordLen + 1];
    [keyword getCharacters:keywordBuffer range:NSMakeRange(0, keywordLen)];
    
    //NSUInteger end = 0;
    NSUInteger keywordIndex = 0;
    [attributedStringText beginEditing];
    for (int i=0; i< len; i++)
    {
        NSString *character = [NSString stringWithFormat:@"%C", buffer[i]];
        
        // We do not care about formatting special characters, if they are part of the name, in any
        // place, we just skip it
        if (!character.isAlphanumeric) {
            continue;
        }
        
        // if our keyword index has advance to be at or beyond the length of the keyword, we are
        // finished, and exit before we have an index out of bounds.
        if (keywordIndex >= keywordLen) {
            break;
        }
        
        // Get the t9 representation of the character and the keyword character at the current index.
        NSString *characterT9 = [self getNumericCharFromAlphabeticString:character];
        NSString *keywordChar = [NSString stringWithFormat:@"%C", keywordBuffer[keywordIndex]];
        if ([characterT9 isEqualToString:keywordChar]) {
            keywordIndex++;
            [attributedStringText setAttributes:boldAttrs range:NSMakeRange(i, 1)];
        } else {
            break;
        }
    }
    
    [attributedStringText endEditing];
    return attributedStringText;
}

+(NSAttributedString *)detailTextWithKeyword:(NSString *)keyword font:(UIFont *)font color:(UIColor *)color phoneNumber:(id<JCPhoneNumberDataSource>)phoneNumber
{
    NSString *number = phoneNumber.number;
    if (!number) {
        return nil;
    }
    
    number = number.numericStringValue;
    NSDictionary *attrs = @{ NSFontAttributeName: font, NSForegroundColorAttributeName: color };
    if (!keyword || !keyword.isNumeric) {
        return [[NSMutableAttributedString alloc] initWithString:phoneNumber.detailText attributes:attrs];
    }
    
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:number attributes:attrs];
    NSDictionary *boldAttrs = @{ NSFontAttributeName: [UIFont boldFontForFont:font], NSForegroundColorAttributeName: color };
    [attributedText setAttributes:boldAttrs range:[number rangeOfString:keyword]];
    
    NSString *formattedNumber = phoneNumber.detailText;
    NSUInteger len = formattedNumber.length;
    unichar buffer[len+1];
    [formattedNumber getCharacters:buffer range:NSMakeRange(0, len)];
    for (int i=0; i<len; i++) {
        NSString *charater = [NSString stringWithFormat:@"%C", buffer[i]];
        if (!charater.isNumeric) {
            NSAttributedString *attributedCharacter = [[NSAttributedString alloc] initWithString:charater attributes:attrs];
            [attributedText insertAttributedString:attributedCharacter atIndex:i];
        }
    }
    return attributedText;
}

#pragma mark - Private -

NSString *const kT9StarKey = @"*";
NSString *const kT9PoundKey = @"#";

NSString *const kT9Row2 = @"2abcàáâäåɑæçǽćčá";
NSString *const kT9Row3 = @"3defďéèêëě";
NSString *const kT9Row4 = @"4ghiíìïîǵ";
NSString *const kT9Row5 = @"5jklḱḱĺ";
NSString *const kT9Row6 = @"6mnoòóöôøñŋǿḿńňő";
NSString *const kT9Row7 = @"7pqrsßɾṕŕśřš";
NSString *const kT9Row8 = @"8tuvťúùüûűů";
NSString *const kT9Row9 = @"9wxyzýẃźž";

NSString *const kT92 = @"2";
NSString *const kT93 = @"3";
NSString *const kT94 = @"4";
NSString *const kT95 = @"5";
NSString *const kT96 = @"6";
NSString *const kT97 = @"7";
NSString *const kT98 = @"8";
NSString *const kT99 = @"9";

/**
 * Coverts an input string to a proper dial string character. If charater is numeric, star or pound, it is returned. If
 * it is A-Z, it is converted to be its numeric equivalent for that character.
 */
+(NSString *)getNumericCharFromAlphabeticString:(NSString *)string
{
    // Numeric strings are returned
    if (string.isNumeric)
        return string;
    
    // We maintain * and #
    if ([string isEqualToString:kT9StarKey] ||
        [string isEqualToString:kT9PoundKey])
        return string;
    
    string = [string lowercaseStringWithLocale:[self locale]];
    
    static NSCharacterSet *row2, *row3, *row4, *row5, *row6, *row7, *row8, *row9;
    static dispatch_once_t pred;        // Lock
    dispatch_once(&pred, ^{             // This code is called at most once per app
        row2 = [NSCharacterSet characterSetWithCharactersInString:kT9Row2];
        row3 = [NSCharacterSet characterSetWithCharactersInString:kT9Row3];
        row4 = [NSCharacterSet characterSetWithCharactersInString:kT9Row4];
        row5 = [NSCharacterSet characterSetWithCharactersInString:kT9Row5];
        row6 = [NSCharacterSet characterSetWithCharactersInString:kT9Row6];
        row7 = [NSCharacterSet characterSetWithCharactersInString:kT9Row7];
        row8 = [NSCharacterSet characterSetWithCharactersInString:kT9Row8];
        row9 = [NSCharacterSet characterSetWithCharactersInString:kT9Row9];
    });
    
    if ([string rangeOfCharacterFromSet:row2].location != NSNotFound) {
        return kT92;
    } else if ([string rangeOfCharacterFromSet:row3].location != NSNotFound) {
        return kT93;
    } else if ([string rangeOfCharacterFromSet:row4].location != NSNotFound) {
        return kT94;
    } else if ([string rangeOfCharacterFromSet:row5].location != NSNotFound) {
        return kT95;
    } else if ([string rangeOfCharacterFromSet:row6].location != NSNotFound) {
        return kT96;
    } else if ([string rangeOfCharacterFromSet:row7].location != NSNotFound) {
        return kT97;
    } else if ([string rangeOfCharacterFromSet:row8].location != NSNotFound) {
        return kT98;
    } else if ([string rangeOfCharacterFromSet:row9].location != NSNotFound) {
        return kT99;
    }
    return nil;
}

+(NSLocale *)locale
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

@end
