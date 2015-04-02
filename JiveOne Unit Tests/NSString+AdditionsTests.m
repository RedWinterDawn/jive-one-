//
//  NSString+AdditionsTests.m
//  JiveOne
//
//  Created by Robert Barclay on 4/2/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

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

@end
