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

@end

