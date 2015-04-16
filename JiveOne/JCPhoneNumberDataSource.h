//
//  JCPhoneNumberDataSource.h
//  JiveOne
//
//  Created by Robert Barclay on 4/10/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

@import Foundation;
@import UIKit;

@protocol JCPhoneNumberDataSource <NSObject>

// What text should be shown to display as a title to represent the person.
@property (nonatomic, readonly) NSString *titleText;

// Returns an attributed string, bolding keywords in the title.
-(NSAttributedString *)titleTextWithKeyword:(NSString *)keyword
                                       font:(UIFont *)font
                                      color:(UIColor *)color;

// What test should bes shown as detail text to represent a person
@property (nonatomic, readonly) NSString *detailText;

// Returns an attributed string, bolding keywords in the detail text.
-(NSAttributedString *)detailTextWithKeyword:(NSString *)keyword
                                        font:(UIFont *)font
                                       color:(UIColor *)color;

// Method to return true if the persons name, number contains a given keyword or its t9 equivalent.
-(BOOL)containsKeyword:(NSString *)keyword;

// Method to return true if the persons name contains a t9 equivalent of the name
-(BOOL)containsT9Keyword:(NSString *)keyword;

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSString *number;
@property (nonatomic, readonly) NSString *dialableNumber;
@property (nonatomic, readonly) NSString *formattedNumber;
@property (nonatomic, readonly) NSString *t9;

@end
