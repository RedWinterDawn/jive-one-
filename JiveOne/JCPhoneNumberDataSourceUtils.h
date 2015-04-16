//
//  JCPhoneNumberDataSourceUtils.h
//  JiveOne
//
//  Created by Robert Barclay on 4/16/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCPhoneNumberDataSource.h"

@interface JCPhoneNumberDataSourceUtils : NSObject

+(BOOL)phoneNumber:(id<JCPhoneNumberDataSource>)phoneNumber containsT9Keyword:(NSString *)keyword;

+(BOOL)phoneNumber:(id<JCPhoneNumberDataSource>)phoneNumber containsKeyword:(NSString *)keyword;

+(BOOL)phoneNumber:(id<JCPhoneNumberDataSource>)phoneNumber isEqual:(id)object;

+(NSString *)t9StringForPhoneNumber:(id<JCPhoneNumberDataSource>)phoneNumber;

+(NSString *)t9StringForString:(NSString *)string;

+(NSString *)dialableStringForPhoneNumber:(id<JCPhoneNumberDataSource>)phoneNumber;

+(NSString *)formattedPhoneNumberForPhoneNumber:(id<JCPhoneNumberDataSource>)phoneNumber;

+(NSAttributedString *)detailTextWithKeyword:(NSString *)keyword
                                        font:(UIFont *)font
                                       color:(UIColor *)color
                                 phoneNumber:(id<JCPhoneNumberDataSource>)phoneNumber;

+(NSAttributedString *)titleTextWithKeyword:(NSString *)keyword
                                       font:(UIFont *)font
                                      color:(UIColor *)color
                                phoneNumber:(id<JCPhoneNumberDataSource>)phoneNumber;
@end
