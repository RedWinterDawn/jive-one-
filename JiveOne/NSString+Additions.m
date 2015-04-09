//
//  NSString+Custom.m
//  JiveOne
//
//  Created by Robert Barclay on 11/27/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "NSString+Additions.h"

@implementation NSString (Custom)

-(BOOL)isEmpty {
    if ([self isKindOfClass:[NSNull class]]) {
        return YES;
    }
    return !self.length;
}

@end

//
//  NSString+MD5Additions.m
//  JiveOne
//
//  Created by Robert Barclay on 1/6/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import <CommonCrypto/CommonDigest.h>

@implementation NSString (MD5Additions)

- (NSString *)MD5Hash
{
    if(self == nil || [self length] == 0)
        return nil;
    
    const char *string = [self UTF8String];
    unsigned char outputBuffer[CC_MD5_DIGEST_LENGTH];
    CC_MD5(string, (unsigned int)strlen(string), outputBuffer);
    
    NSMutableString *outputString = [[NSMutableString alloc] initWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(NSInteger count = 0; count < CC_MD5_DIGEST_LENGTH; count++)
        [outputString appendFormat:@"%02x",outputBuffer[count]];
    return outputString;
}

@end

@implementation NSString (IsNumeric)

-(BOOL)isNumeric {
    NSCharacterSet *numericSet = [NSCharacterSet decimalDigitCharacterSet];
    return [numericSet isSupersetOfSet:[NSCharacterSet characterSetWithCharactersInString:self]];
}

-(BOOL)isAlphanumeric {
    NSCharacterSet *alphaNumericSet = [NSCharacterSet alphanumericCharacterSet];
    return [alphaNumericSet isSupersetOfSet:[NSCharacterSet characterSetWithCharactersInString:self]];
}

-(NSString *)numericStringValue {
    return [[self componentsSeparatedByCharactersInSet: [[NSCharacterSet decimalDigitCharacterSet] invertedSet]] componentsJoinedByString:@""];
}

@end

#import <libPhoneNumber-iOS/NBPhoneNumberUtil.h>
#import <libPhoneNumber-iOS/NBAsYouTypeFormatter.h>

@implementation NSString (PhoneNumbers)

-(NSString *)t9
{
    NSMutableString *t9 = [NSMutableString string];
    NSUInteger length = self.length;
    unichar buffer[length+1];
    [self getCharacters:buffer range:NSMakeRange(0, length)];
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

-(NSString *)dialableString
{
    NSCharacterSet *allowedCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"*+#0123456789"];
    return [[self componentsSeparatedByCharactersInSet:[allowedCharacterSet invertedSet]] componentsJoinedByString:@""];
}

-(NSString *)formattedPhoneNumber
{
    if (self.length < 5)
        return self.dialableString;
    
    static NBPhoneNumberUtil *phoneNumberUtil;
    static dispatch_once_t pred;
    dispatch_once(&pred, ^{
        phoneNumberUtil = [NBPhoneNumberUtil new];
    });
    
    __autoreleasing NSError *error;
    NBPhoneNumber *phoneNumber = [phoneNumberUtil parse:self defaultRegion:@"US" error:&error];
    if (error)
        NSLog(@"%@", [error description]);
    return [phoneNumberUtil format:phoneNumber numberFormat:NBEPhoneNumberFormatNATIONAL error:&error];
}

-(NSMutableAttributedString *)formattedPhoneNumberWithNumericKeyword:(NSString *)keyword font:(UIFont *)font color:(UIColor *)color{
    
    NSString *number = self.numericStringValue;
    NSDictionary *attrs = @{ NSFontAttributeName: font, NSForegroundColorAttributeName: color };
    if (!keyword || !keyword.isNumeric) {
        return [[NSMutableAttributedString alloc] initWithString:number.formattedPhoneNumber attributes:attrs];
    }
    
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:number attributes:attrs];
    NSDictionary *boldAttrs = @{ NSFontAttributeName: [UIFont boldFontForFont:font], NSForegroundColorAttributeName: color };
    [attributedText setAttributes:boldAttrs range:[number rangeOfString:keyword]];
    
    NSString *formattedNumber = self.formattedPhoneNumber;
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

-(NSMutableAttributedString *)formattedStringWithT9Keyword:(NSString *)keyword font:(UIFont *)font color:(UIColor *)color
{
    NSDictionary *attrs = @{ NSFontAttributeName: font, NSForegroundColorAttributeName: color };
    NSMutableAttributedString *attributedStringText = [[NSMutableAttributedString alloc] initWithString:self attributes:attrs];
    if (!keyword || !keyword.isNumeric) {
        return attributedStringText;
    }
    
    NSDictionary *boldAttrs = @{ NSFontAttributeName: [UIFont boldFontForFont:font], NSForegroundColorAttributeName: color };
    
    // Get buffer array of all characters in the string from self.
    NSUInteger len = self.length;
    unichar buffer[len +1];
    [self getCharacters:buffer range:NSMakeRange(0, len)];
    
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
-(NSString *)getNumericCharFromAlphabeticString:(NSString *)string
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

@end

@implementation NSString (Localization)

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

@end

@implementation UIFont (Bold)

+(UIFont *)boldFontForFont:(UIFont *)font
{
    NSString *fontName = [font.fontName stringByAppendingString:@"-Bold"];
    UIFont *boldFont = [UIFont fontWithName:fontName size:font.pointSize];
    if (boldFont) {
        return boldFont;
    }
    
    fontName = [font.fontName stringByAppendingString:@"-BoldMT"];
    boldFont = [UIFont fontWithName:fontName size:font.pointSize];
    if (boldFont) {
        return boldFont;
    }
    
    if ([fontName isEqualToString:@"Arial"]) {
        fontName = @"Arial-BoldMT";
        boldFont = [UIFont fontWithName:fontName size:font.pointSize];
        if (boldFont) {
            return boldFont;
        }
    }
    return [UIFont boldSystemFontOfSize:font.pointSize];
}

@end