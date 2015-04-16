//
//  JCPersonTests.m
//  JiveOne
//
//  Created by Robert Barclay on 4/16/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCBaseTestCase.h"
#import "JCPersonManagedObject.h"
#import "Extension.h"
#import "NSString+Additions.h"

@interface JCPersonTests : JCBaseTestCase

@end

@implementation JCPersonTests

- (void)test_phoneNumberDataSourceProtocol {
    
    // Given
    NSString *jrn = @"jrn:line::jive:01471162-f384-24f5-9351-000100420002:014a5955-b837-e8d0-ab9a-000100620003";
    
    // When
    JCPersonManagedObject *person = [Extension MR_findFirstByAttribute:NSStringFromSelector(@selector(jrn)) withValue:jrn];
    
    // Thus
    XCTAssertNotNil(person, @"We should have a person");
    XCTAssertNotNil(person.name, @"We should have a name");
    XCTAssertNotNil(person.number, @"We should have a number");
//    XCTAssertTrue([person.dialableNumber isEqualToString:person.number.dialableString], @"Dialables do not match");
//    XCTAssertTrue([person.t9 isEqualToString:person.name.t9], @"t9 should equal name");
    XCTAssertTrue([person.titleText isEqualToString:person.name], @"Title should equal name");
    
    // Since we pulled up a jive contact, we can test its detail here.
//    NSString *detail = [NSString stringWithFormat:@"ext: %@", person.number.formattedPhoneNumber];
//    XCTAssertTrue([person.detailText isEqualToString:detail], @"detail text should equal");
}

- (void)test_noName {
    
    // Given
    NSString *jrn = @"jrn:line::jive:01471162-f384-24f5-9351-000100420002:014a5955-b837-e8d0-ab9a-000100620004";
    
    // When
    JCPersonManagedObject *person = [Extension MR_findFirstByAttribute:NSStringFromSelector(@selector(jrn)) withValue:jrn];
    
    // Thus
    XCTAssertNotNil(person, @"We should have a person");
    XCTAssertNil(person.name, @"Name should be nil is not equal");
    XCTAssertNil(person.titleText, @"Title SHould be nil");
    XCTAssertNil(person.t9, @"T9 SHould be nil");
}

- (void)test_containsKeyword_noName_t9Keyword {
    
    // Given
    NSString *jrn = @"jrn:line::jive:01471162-f384-24f5-9351-000100420002:014a5955-b837-e8d0-ab9a-000100620004";
    JCPersonManagedObject *person = [Extension MR_findFirstByAttribute:NSStringFromSelector(@selector(jrn)) withValue:jrn];
    NSString *keyword = @"762";    
}

- (void)test_containsKeyword_noName_numericKeyword {
    
    
}

- (void)test_containsKeyword_noName_noKeyword {
    
    
}

- (void)test_containsKeyword_t9Match {
    
    
}

- (void)test_containsKeyword_numberMatch {
    
    
}

- (void)test_containsKeyword_nameMatch
{
    
}

- (void)test_containsKeyword_numericNoMatch {
    
    
}

- (void)test_containsKeyword_noMatch {
    
}

#pragma mark T9

- (void)test_containsT9_noName {
    
}

- (void)test_containsT9_noKeyword {
    
}

- (void)test_containsT9_match {
    
}

- (void)test_containT9_noMatch {
    
}

@end
