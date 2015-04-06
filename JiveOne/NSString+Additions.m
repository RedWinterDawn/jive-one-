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

-(bool)isNumeric {
    NSCharacterSet *alphaNums = [NSCharacterSet decimalDigitCharacterSet];
    NSCharacterSet *inStringSet = [NSCharacterSet characterSetWithCharactersInString:self];
    return [alphaNums isSupersetOfSet:inStringSet];
}

-(NSString *)numericStringValue {
    return [[self componentsSeparatedByCharactersInSet: [[NSCharacterSet decimalDigitCharacterSet] invertedSet]] componentsJoinedByString:@""];
}

@end

#import <libPhoneNumber-iOS/NBPhoneNumberUtil.h>
#import <libPhoneNumber-iOS/NBAsYouTypeFormatter.h>

@implementation NSString (PhoneNumbers)

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

-(NSMutableAttributedString *)formattedPhoneNumberWithKeyword:(NSString *)keyword font:(UIFont *)font color:(UIColor *)color{
    
    NSString *number = self.numericStringValue;
    NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                           font, NSFontAttributeName,
                           color, NSForegroundColorAttributeName, nil];
    
    NSMutableAttributedString *attributedNumberText = [[NSMutableAttributedString alloc] initWithString:number attributes:attrs];
    
    UIFont *boldFont = [UIFont boldFontForFont:font];
    NSDictionary *boldAttrs = [NSDictionary dictionaryWithObjectsAndKeys:
                               boldFont, NSFontAttributeName,
                               color, NSForegroundColorAttributeName, nil];
    
    NSRange range = [number rangeOfString:keyword];
    [attributedNumberText setAttributes:boldAttrs range:range];
    
    NSString *formattedNumber = self.formattedPhoneNumber;
    NSUInteger len = formattedNumber.length;
    unichar buffer[len+1];
    [formattedNumber getCharacters:buffer range:NSMakeRange(0, len)];
    for (int i=0; i<len; i++) {
        NSString *charater = [NSString stringWithFormat:@"%C", buffer[i]];
        if (!charater.isNumeric) {
            NSAttributedString *attributedCharacter = [[NSAttributedString alloc] initWithString:charater attributes:attrs];
            [attributedNumberText insertAttributedString:attributedCharacter atIndex:i];
        }
    }
    
    return attributedNumberText;
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