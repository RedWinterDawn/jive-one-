//
//  NSString+AdditionsTests.m
//  JiveOne
//
//  Created by Robert Barclay on 4/2/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "NSString+Additions.h"

@interface NSString_AdditionsTests : XCTestCase

@end

@implementation NSString_AdditionsTests

#pragma mark - Numeric Tests -

-(void)test_isNumeric
{
    NSString *testString = @"12345";
    XCTAssertTrue(testString.isNumeric);
    
    testString = @"abcd";
    XCTAssertFalse(testString.isNumeric);
    
    testString = @"a1b2c3d4";
    XCTAssertFalse(testString.isNumeric);
}

-(void)test_isAlphaNumeric
{
    NSString *testString = @"12345";
    XCTAssertTrue(testString.isAlphanumeric);
    
    testString = @"abcd";
    XCTAssertTrue(testString.isAlphanumeric);
    
    testString = @"a1b2c3d4";
    XCTAssertTrue(testString.isAlphanumeric);
    
    testString = @"!a1b2c3d4";
    XCTAssertFalse(testString.isAlphanumeric);
}

-(void)test_numericStringValue
{
    // Given
    NSString *testString = @"1a2b3c4d 5e6f7g8h9!@#$%^&*0";
    
    // When
    NSString *result = testString.numericStringValue;
    
    // Then
    XCTAssertTrue([result isEqualToString:@"1234567890"], @"Numeric String test failed");
}

#pragma mark - Phone Number Tests -

-(void)test_dialableString
{
    // Given
    NSString *testString = @"+1 (555) 123-4567 *8910abcedfghijklmnopqrstuv!@#$%^&=-_~`()";
    
    // When
    NSString *result = testString.dialableString;
    
    // Then
    XCTAssertTrue([result isEqualToString:@"+15551234567*8910#"], @"Dialable String failed");
}

-(void)test_t9String
{
    // Given
    NSString *string = @"Robert Barclay";
    NSString *expectedResult = @"7623782272529";
    
    // When
    NSString *result = string.t9;
    
    // Then
    XCTAssertTrue([result isEqualToString:expectedResult], @"t9 did not match expected result");
}

-(void)test_attributedFormattedPhoneNumberString_nonNumericKeyword
{
    // Given
    NSString *string = @"555-525-5355";
    NSString *keyword = @"Hi";
    UIFont *font = [UIFont systemFontOfSize:12];
    UIColor *color = [UIColor blackColor];
    
    // When
    NSMutableAttributedString *result = [string formattedPhoneNumberWithNumericKeyword:keyword font:font color:color];
    
    // Then
    NSString *expectedString = @"(555) 525-5355";
    NSDictionary *attrs = @{ NSFontAttributeName: font, NSForegroundColorAttributeName: color };
    NSMutableAttributedString *expectedAttributedString = [[NSMutableAttributedString alloc] initWithString:expectedString attributes:attrs];
    
    XCTAssertTrue([expectedAttributedString isEqualToAttributedString:result], @"Strings should be equal");
}

-(void)test_attributedFormattedPhoneNumberString_numericKeyword
{
    // Given
    NSString *string = @"555-525-5355";
    UIFont *font = [UIFont systemFontOfSize:12];
    UIColor *color = [UIColor blackColor];
    NSString *keyword = @"5555";
    
    // When
    NSMutableAttributedString *result = [string formattedPhoneNumberWithNumericKeyword:keyword font:font color:color];
    
    // Then
    NSString *expectedString = @"(555) 525-5355";
    NSDictionary *attrs = @{ NSFontAttributeName: font, NSForegroundColorAttributeName: color };
    NSDictionary *boldAttrs = @{ NSFontAttributeName: [UIFont boldFontForFont:font], NSForegroundColorAttributeName: color };
    NSMutableAttributedString *expectedAttributedString = [[NSMutableAttributedString alloc] initWithString:expectedString attributes:attrs];
    [expectedAttributedString beginEditing];
    [expectedAttributedString setAttributes:boldAttrs range:NSMakeRange(1, 3)];
    [expectedAttributedString setAttributes:boldAttrs range:NSMakeRange(6, 1)];
    [expectedAttributedString endEditing];
    
    XCTAssertTrue([expectedAttributedString isEqualToAttributedString:result], @"Strings should be equal");
}

-(void)test_attributedStringFromT9_keywordNonNumeric
{
    // Given
    NSString *string = @"Robert Barclay";
    UIFont *font = [UIFont systemFontOfSize:12];
    UIColor *color = [UIColor blackColor];
    NSString *keyword = @"Hi"; // non numeric string
    
    // When
    NSMutableAttributedString *result = [string formattedStringWithT9Keyword:keyword font:font color:color];
    
    // Then
    NSDictionary *attrs = @{NSFontAttributeName: font, NSForegroundColorAttributeName: color};
    NSMutableAttributedString *expectedAttributedString = [[NSMutableAttributedString alloc] initWithString:string attributes:attrs];
    
    XCTAssertTrue([expectedAttributedString isEqualToAttributedString:result], @"Strings should be equal");
}


-(void)test_attributedStringFromT9_keywordBeginningOfWord
{
    // Given
    NSString *string = @"Robert Barclay";
    UIFont *font = [UIFont systemFontOfSize:12];
    UIColor *color = [UIColor blackColor];
    NSString *keyword = @"762"; // T9 for rob
    
    // When
    NSMutableAttributedString *result = [string formattedStringWithT9Keyword:keyword font:font color:color];

    // Then
    NSDictionary *attrs = @{ NSFontAttributeName: font, NSForegroundColorAttributeName:color };
    NSDictionary *boldAttrs = @{ NSFontAttributeName: [UIFont boldFontForFont:font], NSForegroundColorAttributeName: color };
    NSMutableAttributedString *expectedAttributedString = [[NSMutableAttributedString alloc] initWithString:string attributes:attrs];
    [expectedAttributedString beginEditing];
    [expectedAttributedString setAttributes:boldAttrs range:NSMakeRange(0, 3)];
    [expectedAttributedString endEditing];
    
    XCTAssertTrue([expectedAttributedString isEqualToAttributedString:result], @"Strings should be equal");
}

-(void)test_attributedStringFromT9_keywordMiddleOfWord
{
    // Given
    NSString *string = @"Barclay Robert";
    UIFont *font = [UIFont systemFontOfSize:12];
    UIColor *color = [UIColor blackColor];
    NSString *keyword = @"762"; // T9 for rob
    
    // When
    NSMutableAttributedString *result = [string formattedStringWithT9Keyword:keyword font:font color:color];
    
    // Then
    NSDictionary *attrs = @{ NSFontAttributeName: font, NSForegroundColorAttributeName:color };
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:string attributes:attrs];
    
    XCTAssertTrue([attributedString isEqualToAttributedString:result], @"Strings should be equal");
}

@end

