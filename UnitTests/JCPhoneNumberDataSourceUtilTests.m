//
//  JCPhoneNumberDataSourceUtilTests.m
//  JiveOne
//
//  Created by Robert Barclay on 4/16/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "JCPhoneNumber.h"
#import "JCPhoneNumberDataSourceUtils.h"
#import "NSString+Additions.h"

@interface JCPhoneNumberDataSourceUtilTests : XCTestCase

@end

@implementation JCPhoneNumberDataSourceUtilTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

-(void)test_dialableNumber
{
    // Given
    NSString *garbage = @"+1 (555) 123-4567 *8910abcedfghijklmnopqrstuv!@#$%^&=-_~`()";
    JCPhoneNumber *phoneNumber = [JCPhoneNumber phoneNumberWithName:nil number:garbage];

    // When
    NSString *result = [JCPhoneNumberDataSourceUtils dialableStringForPhoneNumber:phoneNumber];

    // Then
    XCTAssertTrue([result isEqualToString:@"+15551234567*8910#"], @"Dialable String failed");
}

-(void)test_t9String
{
    // Given
    NSString *name = @"Robert Barclay";
    NSString *number = @"+1 (555) 123-4444";
    JCPhoneNumber *phoneNumber = [JCPhoneNumber phoneNumberWithName:name number:number];
    NSString *expectedResult = @"7623782272529";

    // When
    NSString *result = [JCPhoneNumberDataSourceUtils t9StringForPhoneNumber:phoneNumber];

    // Then
    XCTAssertTrue([result isEqualToString:expectedResult], @"t9 did not match expected result");
}

-(void)test_attributedFormattedPhoneNumberString_nonNumericKeyword
{
    // Given
    NSString *number = @"555-525-5355";
    JCPhoneNumber *phoneNumber = [JCPhoneNumber phoneNumberWithName:nil number:number];
    NSString *keyword = @"Hi";
    UIFont *font = [UIFont systemFontOfSize:12];
    UIColor *color = [UIColor blackColor];

    // When
    NSAttributedString *result = [JCPhoneNumberDataSourceUtils detailTextWithKeyword:keyword font:font color:color phoneNumber:phoneNumber];

    // Then
    NSString *expectedString = @"(555) 525-5355";
    NSDictionary *attrs = @{ NSFontAttributeName: font, NSForegroundColorAttributeName: color };
    NSMutableAttributedString *expectedAttributedString = [[NSMutableAttributedString alloc] initWithString:expectedString attributes:attrs];

    XCTAssertTrue([expectedAttributedString isEqualToAttributedString:result], @"Strings should be equal");
}

-(void)test_attributedFormattedPhoneNumberString_numericKeyword
{
    // Given
    NSString *number = @"555-525-5355";
    JCPhoneNumber *phoneNumber = [JCPhoneNumber phoneNumberWithName:nil number:number];
    UIFont *font = [UIFont systemFontOfSize:12];
    UIColor *color = [UIColor blackColor];
    NSString *keyword = @"5555";

    // When
    NSAttributedString *result = [JCPhoneNumberDataSourceUtils detailTextWithKeyword:keyword font:font color:color phoneNumber:phoneNumber];

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
    NSString *name = @"Robert Barclay";
    NSString *number = @"555-525-5355";
    JCPhoneNumber *phoneNumber = [JCPhoneNumber phoneNumberWithName:name number:number];
    UIFont *font = [UIFont systemFontOfSize:12];
    UIColor *color = [UIColor blackColor];
    NSString *keyword = @"Hi"; // non numeric string

    // When
    NSAttributedString *result = [JCPhoneNumberDataSourceUtils titleTextWithKeyword:keyword font:font color:color phoneNumber:phoneNumber];

    // Then
    NSDictionary *attrs = @{NSFontAttributeName: font, NSForegroundColorAttributeName: color};
    NSMutableAttributedString *expectedAttributedString = [[NSMutableAttributedString alloc] initWithString:name attributes:attrs];

    XCTAssertTrue([expectedAttributedString isEqualToAttributedString:result], @"Strings should be equal");
}


-(void)test_attributedStringFromT9_keywordBeginningOfWord
{
    // Given
    NSString *name = @"Robert Barclay";
    NSString *number = @"555-525-5355";
    JCPhoneNumber *phoneNumber = [JCPhoneNumber phoneNumberWithName:name number:number];
    UIFont *font = [UIFont systemFontOfSize:12];
    UIColor *color = [UIColor blackColor];
    NSString *keyword = @"762"; // T9 for rob

    // When
    NSAttributedString *result = [JCPhoneNumberDataSourceUtils titleTextWithKeyword:keyword font:font color:color phoneNumber:phoneNumber];

    // Then
    NSDictionary *attrs = @{ NSFontAttributeName: font, NSForegroundColorAttributeName:color };
    NSDictionary *boldAttrs = @{ NSFontAttributeName: [UIFont boldFontForFont:font], NSForegroundColorAttributeName: color };
    NSMutableAttributedString *expectedAttributedString = [[NSMutableAttributedString alloc] initWithString:name attributes:attrs];
    [expectedAttributedString beginEditing];
    [expectedAttributedString setAttributes:boldAttrs range:NSMakeRange(0, 3)];
    [expectedAttributedString endEditing];

    XCTAssertTrue([expectedAttributedString isEqualToAttributedString:result], @"Strings should be equal");
}

-(void)test_attributedStringFromT9_keywordMiddleOfWord
{
    // Given
    NSString *name = @"Barclay Robert";
    NSString *number = @"555-525-5355";
    JCPhoneNumber *phoneNumber = [JCPhoneNumber phoneNumberWithName:name number:number];
    UIFont *font = [UIFont systemFontOfSize:12];
    UIColor *color = [UIColor blackColor];
    NSString *keyword = @"762"; // T9 for rob

    // When
    NSAttributedString *result = [JCPhoneNumberDataSourceUtils titleTextWithKeyword:keyword font:font color:color phoneNumber:phoneNumber];

    // Then
    NSDictionary *attrs = @{ NSFontAttributeName: font, NSForegroundColorAttributeName:color };
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:name attributes:attrs];

    XCTAssertTrue([attributedString isEqualToAttributedString:result], @"Strings should be equal");
}

@end
