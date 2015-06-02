//
//  JCPhoneNumberTests.m
//  JiveOne
//
//  Created by Robert Barclay on 4/15/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "JCPhoneNumber.h"
#import "NSString+Additions.h"

@interface JCPhoneNumberTests : XCTestCase

@end

@implementation JCPhoneNumberTests

- (void)test_conviencenceMethod {
    
    // Given
    NSString *name = @"rob";
    NSString *number = @"+1 (555) 123-4444";
    
    // When
    JCPhoneNumber *phoneNumber = [JCPhoneNumber phoneNumberWithName:name number:number];
    
    // Thus
//    XCTAssertTrue([phoneNumber.name isEqualToString:name], @"Names is not equal");
//    XCTAssertTrue([phoneNumber.number isEqualToString:number], @"Numbers are not equal");
//    XCTAssertTrue([phoneNumber.dialableNumber isEqualToString:number.dialableString], @"Dialables do not match");
//    XCTAssertTrue([phoneNumber.t9 isEqualToString:name.t9], @"t9 should equal name");
//    XCTAssertTrue([phoneNumber.titleText isEqualToString:name], @"Title should equal name");
//    XCTAssertTrue([phoneNumber.detailText isEqualToString:number.formattedPhoneNumber], @"detail text should equal formatted phone");
}

- (void)test_noName {
    
    // Given
    NSString *name = nil;
    NSString *number = @"+1 (555) 123-4444";
    
    // When
    JCPhoneNumber *phoneNumber = [[JCPhoneNumber alloc] initWithName:name number:number];

    // Thus
    XCTAssertNil(phoneNumber.name, @"Name should be nil is not equal");
    XCTAssertNil(phoneNumber.titleText, @"Title SHould be nil");
    XCTAssertNil(phoneNumber.t9, @"T9 SHould be nil");
}

- (void)test_noNumber {
    
    // Given
    NSString *name = @"test";
    NSString *number = nil;
    
    // When
    JCPhoneNumber *phoneNumber = [[JCPhoneNumber alloc] initWithName:name number:number];
    
    // Thus
    XCTAssertNil(phoneNumber, @"Phone Number should be nil is not equal");
}

- (void)test_containsKeyword_noName_t9Keyword {
    
    // Given
    NSString *name = nil;
    NSString *number = @"+1 (555) 123-4444";
    JCPhoneNumber *phoneNumber = [JCPhoneNumber phoneNumberWithName:name number:number];
    NSString *keyword = @"723";

    BOOL result = [phoneNumber containsKeyword:keyword];
    XCTAssertFalse(result, @"Result should be false");
}

- (void)test_containsKeyword_noName_numericKeyword {
    
    // Given
    NSString *name = nil;
    NSString *number = @"+1 (555) 123-4444";
    JCPhoneNumber *phoneNumber = [JCPhoneNumber phoneNumberWithName:name number:number];
    NSString *keyword = @"51234";
    
    // When
    BOOL result = [phoneNumber containsKeyword:keyword];
    
    // Thus
    XCTAssertTrue(result, @"Result should be false");
}

- (void)test_containsKeyword_noName_noKeyword {
    
    // Given
    NSString *name = nil;
    NSString *number = @"+1 (555) 123-4444";
    JCPhoneNumber *phoneNumber = [JCPhoneNumber phoneNumberWithName:name number:number];
    NSString *keyword = nil;
    
    // When
    BOOL result = [phoneNumber containsKeyword:keyword];
    
    // Thus
    XCTAssertFalse(result, @"Result should be false");
}

- (void)test_containsKeyword_t9Match {
    
    // Given
    NSString *name = @"Robert";
    NSString *number = @"+1 (555) 123-4444";
    JCPhoneNumber *phoneNumber = [JCPhoneNumber phoneNumberWithName:name number:number];
    NSString *keyword = @"762";
    
    // When
    BOOL result = [phoneNumber containsKeyword:keyword];
    
    // Thus
    XCTAssertTrue(result, @"Result should be true");
}

- (void)test_containsKeyword_numberMatch {
    
    // Given
    NSString *name = @"Robert";
    NSString *number = @"+1 (555) 123-4444";
    JCPhoneNumber *phoneNumber = [JCPhoneNumber phoneNumberWithName:name number:number];
    NSString *keyword = @"51234";
    
    // When
    BOOL result = [phoneNumber containsKeyword:keyword];
    
    // Thus
    XCTAssertTrue(result, @"Result should be true");
}

- (void)test_containsKeyword_nameMatch
{
    // Given
    NSString *name = @"Robert";
    NSString *number = @"+1 (555) 123-4444";
    JCPhoneNumber *phoneNumber = [JCPhoneNumber phoneNumberWithName:name number:number];
    NSString *keyword = @"Rob";
    
    // When
    BOOL result = [phoneNumber containsKeyword:keyword];
    
    // Thus
    XCTAssertTrue(result, @"Result should be true");
}

- (void)test_containsKeyword_numericNoMatch {
    
    // Given
    NSString *name = @"Robert";
    NSString *number = @"+1 (555) 123-4444";
    JCPhoneNumber *phoneNumber = [JCPhoneNumber phoneNumberWithName:name number:number];
    NSString *keyword = @"4321";
    
    // When
    BOOL result = [phoneNumber containsKeyword:keyword];
    
    // Thus
    XCTAssertFalse(result, @"Result should be false");
}

- (void)test_containsKeyword_noMatch {
    
    // Given
    NSString *name = @"Robert";
    NSString *number = @"+1 (555) 123-4444";
    JCPhoneNumber *phoneNumber = [JCPhoneNumber phoneNumberWithName:name number:number];
    NSString *keyword = @"blah";
    
    // When
    BOOL result = [phoneNumber containsKeyword:keyword];
    
    // Thus
    XCTAssertFalse(result, @"Result should be false");
}

#pragma mark T9

- (void)test_containsT9_noName {
    
    // Given
    NSString *name = nil;
    NSString *number = @"+1 (555) 123-4444";
    JCPhoneNumber *phoneNumber = [JCPhoneNumber phoneNumberWithName:name number:number];
    NSString *keyword = @"762";
    
    // When
    BOOL result = [phoneNumber containsT9Keyword:keyword];
    
    // Thus
    XCTAssertFalse(result, @"Result should be false");
    
}

- (void)test_containsT9_noKeyword {
    // Given
    NSString *name = @"Robert";
    NSString *number = @"+1 (555) 123-4444";
    JCPhoneNumber *phoneNumber = [JCPhoneNumber phoneNumberWithName:name number:number];
    NSString *keyword = nil;
    
    // When
    BOOL result = [phoneNumber containsT9Keyword:keyword];
    
    // Thus
    XCTAssertFalse(result, @"Result should be false");
}

- (void)test_containsT9_match {
    // Given
    NSString *name = @"Robert";
    NSString *number = @"+1 (555) 123-4444";
    JCPhoneNumber *phoneNumber = [JCPhoneNumber phoneNumberWithName:name number:number];
    NSString *keyword = @"762";
    
    // When
    BOOL result = [phoneNumber containsT9Keyword:keyword];
    
    // Thus
    XCTAssertTrue(result, @"Result should be true");
}

- (void)test_containT9_noMatch {
    // Given
    NSString *name = @"Robert";
    NSString *number = @"+1 (555) 123-4444";
    JCPhoneNumber *phoneNumber = [JCPhoneNumber phoneNumberWithName:name number:number];
    NSString *keyword = @"555";
    
    // When
    BOOL result = [phoneNumber containsT9Keyword:keyword];
    
    // Thus
    XCTAssertFalse(result, @"Result should be false");
}


@end
