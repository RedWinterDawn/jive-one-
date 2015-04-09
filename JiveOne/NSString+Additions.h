//
//  NSString+Custom.h
//  JiveOne
//
//  Created by Robert Barclay on 11/27/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface NSString (Validations)

-(BOOL)isEmpty;

@end

@interface NSString (MD5Additions)

- (NSString *)MD5Hash;

@end

@interface NSString (IsNumeric)

@property (nonatomic, readonly) bool isNumeric;
@property (nonatomic, readonly) bool isAlphanumeric;
@property (nonatomic, readonly) NSString *numericStringValue;

@end


@interface NSString (PhoneNumbers)

@property (nonatomic, readonly) NSString *t9;
@property (nonatomic, readonly) NSString *dialableString;
@property (nonatomic, readonly) NSString *formattedPhoneNumber;

- (NSMutableAttributedString *)formattedPhoneNumberWithNumericKeyword:(NSString *)keyword font:(UIFont *)font color:(UIColor *)color;
- (NSMutableAttributedString *)formattedStringWithT9Keyword:(NSString *)keyword font:(UIFont *)font color:(UIColor *)color;

@end

@interface NSString (Localization)

@property (nonatomic, readonly) NSLocale *locale;

@end

@interface UIFont (Bold)

+(UIFont *)boldFontForFont:(UIFont *)font;

@end