//
//  JCAuthTests.m
//  JCAuthTests
//
//  Created by P Leonard on 3/24/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "JCAuthClient.h"

@interface JCAuthClientTests : XCTestCase

@end

@implementation JCAuthClientTests

- (void)test_succesfull_login {
    
    // IF
    NSString *user = @"jivetesting10";
    NSString *password = nil;
    JCAuthClient *client = [JCAuthClient new];
    XCTestExpectation login = [self expectationWithDescription:@"login"];
    
    // When
    [[JCAuthClient new] loginWithUsername:user password:password completed:^(BOOL success, NSError *error) {
        [login fulfill];
    }];
    
    // Then
    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
        XCTAssertNotNil(crap, @"No result recevied.");
    }];
}

- (void)test_null_user_login {
    
    // IF
    NSString *user = @"jivetesting10";
    NSString *password = nil;
    JCAuthClient *client = [JCAuthClient new];
    XCTestExpectation login = [self expectationWithDescription:@"login"];
    
    // When
    [[JCAuthClient new] loginWithUsername:user password:password completed:^(BOOL success, NSError *error) {
        [login fulfill];
    }];
    
    // Then
    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
        XCTAssertNotNil(crap, @"No result recevied.");
    }];
}

- (void)test_null_password_login {
    // IF
    NSString *user = @"jivetesting10";
    NSString *password = nil;
    JCAuthClient *client = [JCAuthClient new];
    XCTestExpectation login = [self expectationWithDescription:@"login"];
    
    // When
    [[JCAuthClient new] loginWithUsername:user password:password completed:^(BOOL success, NSError *error) {
        [login fulfill];
    }];
    
    // Then
    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
        XCTAssertNotNil(crap, @"No result recevied.");
    }];
}

- (void)test_invalid_user_login {
    // IF
    NSString *user = @"jivetesting10";
    NSString *password = nil;
    JCAuthClient *client = [JCAuthClient new];
    XCTestExpectation login = [self expectationWithDescription:@"login"];
    
    // When
    [[JCAuthClient new] loginWithUsername:user password:password completed:^(BOOL success, NSError *error) {
        [login fulfill];
    }];
    
    // Then
    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
        XCTAssertNotNil(crap, @"No result recevied.");
    }];
}

- (void)test_invalid_password_login {
    // IF
    NSString *user = @"jivetesting10";
    NSString *password = nil;
    JCAuthClient *client = [JCAuthClient new];
    XCTestExpectation login = [self expectationWithDescription:@"login"];
    
    // When
    [[JCAuthClient new] loginWithUsername:user password:password completed:^(BOOL success, NSError *error) {
        [login fulfill];
    }];
    
    // Then
    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
        XCTAssertNotNil(crap, @"No result recevied.");
    }];
}

@end
