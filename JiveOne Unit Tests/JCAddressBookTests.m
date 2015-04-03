//
//  JCAddressBookTests.m
//  JiveOne
//
//  Created by Robert Barclay on 3/30/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "JCAddressBook.h"
#import "JCAddressBookTestDataFactory.h"

@interface JCAddressBook ()

- (instancetype)initWithPeople:(NSArray *)people numbers:(NSArray *)numbers;

@end

@interface JCAddressBookTests : XCTestCase

@property (nonatomic, strong) JCAddressBook *addressBook;

@end

@implementation JCAddressBookTests

- (void)setUp {
    [super setUp];
    
    NSDictionary *addressBookData = [JCAddressBookTestDataFactory loadTestAddessBookData];
    XCTAssertNotNil(addressBookData, @"addressBookData should not be null");
    XCTAssertTrue(addressBookData.allKeys.count == 2, @"Invalid addressBookData results");
    
    NSMutableArray *people  = [addressBookData objectForKey:kJCAddressBookPeople];
    XCTAssertNotNil(people, @"people should not be null");
    XCTAssertTrue(people.count == 7, @"people should not be null");
    
    NSMutableArray *numbers = [addressBookData objectForKey:kJCAddressBookNumbers];
    XCTAssertNotNil(numbers, @"numbers should not be null");
    XCTAssertTrue(numbers.count == 14, @"numbers should not be null");
    
    JCAddressBook *addressBook = [[JCAddressBook alloc] initWithPeople:people numbers:numbers];
    self.addressBook = addressBook;
}

- (void)tearDown {
    self.addressBook = nil;
    [super tearDown];
}

- (void)test_fetchAllNumbers {
    
    NSArray *decending = [self.addressBook fetchAllNumbersAscending:NO];
    NSArray *ascending = [self.addressBook fetchAllNumbersAscending:YES];
    
    XCTAssertTrue(decending.count == 14, @"not enough objects returned, should be 14");
    XCTAssertTrue(decending.count == ascending.count, @"not the same number of objects");
    XCTAssertTrue([decending.lastObject isKindOfClass:[JCAddressBookNumber class]], @"wrong class returned");
    XCTAssertEqual(decending.lastObject, ascending.firstObject, @"objects do not match");
    XCTAssertEqual(ascending.lastObject, decending.firstObject, @"objects do not match");
}

- (void)test_fetchAllNumbers_sortedName
{
    NSString *expected = @"Cynthia";
    NSArray *numbers = [self.addressBook fetchAllNumbersSortedByKey:@"firstName" ascending:YES];
    XCTAssertTrue(numbers.count == 14, @"not enough objects returned, should be 14");
    
    JCAddressBookNumber *number = numbers.firstObject;
    XCTAssertTrue([number isKindOfClass:[JCAddressBookNumber class]], @"wrong class returned");
    XCTAssertTrue([number.firstName isEqualToString:expected], @"first name does not match expected");
    
    expected = @"Doe";
    numbers = [self.addressBook fetchAllNumbersSortedByKey:@"lastName" ascending:YES];
    XCTAssertTrue(numbers.count == 14, @"not enough objects returned, should be 14");
    
    number = numbers.firstObject;
    XCTAssertTrue([number isKindOfClass:[JCAddressBookNumber class]], @"wrong class returned");
    XCTAssertTrue([number.lastName isEqualToString:expected], @"last name does not match expected");
    
    expected = @"Cynthia Roberts";
    numbers = [self.addressBook fetchAllNumbersSortedByKey:@"name" ascending:YES];
    XCTAssertTrue(numbers.count == 14, @"not enough objects returned, should be 14");
    
    number = numbers.firstObject;
    XCTAssertTrue([number isKindOfClass:[JCAddressBookNumber class]], @"wrong class returned");
    XCTAssertTrue([number.name isEqualToString:expected], @"name does not match expected");
}

- (void)test_fetchAllNumbers_sortedNumber
{
    NSString *expected = @"(512) 111-1111";
    NSString *expectedName = @"Joe User";
    NSString *expectedType = @"Mobile";
    
    NSArray *numbers = [self.addressBook fetchAllNumbersSortedByKey:@"number" ascending:YES];
    XCTAssertTrue(numbers.count == 14, @"not enough objects returned, should be 14");
    
    JCAddressBookNumber *number = numbers.firstObject;
    XCTAssertTrue([number isKindOfClass:[JCAddressBookNumber class]], @"wrong class returned");
    XCTAssertTrue([number.number isEqualToString:expected], @"number does not match expected");
    XCTAssertTrue([number.name isEqualToString:expectedName], @"name does not match expected");
    XCTAssertTrue([number.type isEqualToString:expectedType], @"type does not match expected");
}

- (void)test_fetchNumbers_numericKeyword
{
    NSString *keyword = @"121";
    NSString *expectedName = @"Joe User";
    NSString *expectedType = @"Mobile";
    NSString *expectedNumber = @"(512) 111-1111";
    
    NSArray *numbers = [self.addressBook fetchNumbersWithKeyword:keyword sortedByKey:@"name" ascending:YES];
    XCTAssertTrue(numbers.count == 1, @"not enough objects returned, should be 1");
    
    JCAddressBookNumber *number = numbers.firstObject;
    XCTAssertTrue([number isKindOfClass:[JCAddressBookNumber class]], @"wrong class returned");
    XCTAssertTrue([number.number isEqualToString:expectedNumber], @"number does not match expected");
    XCTAssertTrue([number.name isEqualToString:expectedName], @"name does not match expected");
    XCTAssertTrue([number.type isEqualToString:expectedType], @"type does not match expected");
    
    keyword = @"9";
    expectedName = @"Jack Doe";
    expectedType = @"Home";
    expectedNumber = @"(512) 999-9999";
    
    numbers = [self.addressBook fetchNumbersWithKeyword:keyword sortedByKey:@"name" ascending:YES];
    XCTAssertTrue(numbers.count == 2, @"not enough objects returned, should be 2");
    
    number = numbers.firstObject;
    XCTAssertTrue([number isKindOfClass:[JCAddressBookNumber class]], @"wrong class returned");
    XCTAssertTrue([number.number isEqualToString:expectedNumber], @"number does not match expected");
    XCTAssertTrue([number.name isEqualToString:expectedName], @"name does not match expected");
    XCTAssertTrue([number.type isEqualToString:expectedType], @"type does not match expected");
}

- (void)test_fetchNumbers_nameKeyword
{
    NSString *keyword = @"joe";
    NSString *expectedName = @"Joe User";
    NSString *expectedType = @"Mobile";
    NSString *expectedNumber = @"(512) 111-1111";
    
    NSArray *numbers = [self.addressBook fetchNumbersWithKeyword:keyword sortedByKey:@"name" ascending:YES];
    XCTAssertTrue(numbers.count == 2, @"not enough objects returned, should be 2");
    
    JCAddressBookNumber *number = numbers.firstObject;
    XCTAssertTrue([number isKindOfClass:[JCAddressBookNumber class]], @"wrong class returned");
    XCTAssertTrue([number.number isEqualToString:expectedNumber], @"number does not match expected");
    XCTAssertTrue([number.name isEqualToString:expectedName], @"name does not match expected");
    XCTAssertTrue([number.type isEqualToString:expectedType], @"type does not match expected");
    
    keyword = @"CYNTHIA";
    expectedName = @"Cynthia Roberts";
    expectedType = @"iPhone";
    expectedNumber = @"(512) 565-6565";
    
    numbers = [self.addressBook fetchNumbersWithKeyword:keyword sortedByKey:@"name" ascending:YES];
    XCTAssertTrue(numbers.count == 1, @"not enough objects returned, should be 1");
    
    number = numbers.firstObject;
    XCTAssertTrue([number isKindOfClass:[JCAddressBookNumber class]], @"wrong class returned");
    XCTAssertTrue([number.number isEqualToString:expectedNumber], @"number does not match expected");
    XCTAssertTrue([number.name isEqualToString:expectedName], @"name does not match expected");
    XCTAssertTrue([number.type isEqualToString:expectedType], @"type does not match expected");
}

@end
