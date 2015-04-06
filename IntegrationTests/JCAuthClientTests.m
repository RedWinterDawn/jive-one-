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

- (void)test_client_initialization {
    
    // IF
    JCAuthClient *authClient = [JCAuthClient new];
    
    XCTAssertEqual(authClient.maxloginAttempts, 2);
    
    authClient.maxloginAttempts = 3;
    
    XCTAssertEqual(authClient.maxloginAttempts, 3);
    
    authClient = [JCAuthClient new];
    
    XCTAssertEqual(authClient.maxloginAttempts, 2);
}

- (void)test_succesfull_login {
    
    // IF
    NSString *user = @"jivetesting11@gmail.com";
    NSString *password = @"testing12";
    XCTestExpectation *login = [self expectationWithDescription:@"login"];
    
    // When
    JCAuthClient *authClient = [JCAuthClient new];
    [authClient loginWithUsername:user password:password completion:^(BOOL success, NSDictionary *authToken, NSError *error) {
        
        XCTAssert(success, @"Failure");
        XCTAssertNotNil(authToken, @"Auth token is nil");
        XCTAssertNil(error, @"Error is not null");
        
        [login fulfill];
    }];
    
    // Then
    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
        XCTAssertNil(error);
    }];
}

- (void)test_null_user_login {
    
    // IF
    NSString *user = nil;
    NSString *password = @"testing12";
    XCTestExpectation *login = [self expectationWithDescription:@"login"];
    
    // When
    JCAuthClient *authClient = [JCAuthClient new];
    [authClient loginWithUsername:user password:password completion:^(BOOL success, NSDictionary *authToken, NSError *error) {
        
        XCTAssertFalse(success, @"Failure");
        XCTAssertNil(authToken, @"Auth token is nil");
        XCTAssertNotNil(error, @"There Should be an error because you have nothing in the username feild");
        
        [login fulfill];
    }];
    
    // Then
    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
        XCTAssertNil(error);
    }];
}

- (void)test_null_password_login {
   
    // IF
    NSString *user = @"jivetesting11@gmail.com";
    NSString *password = nil;
    XCTestExpectation *login = [self expectationWithDescription:@"login"];
    
    // When
    JCAuthClient *authClient = [JCAuthClient new];
    [authClient loginWithUsername:user password:password completion:^(BOOL success, NSDictionary *authToken, NSError *error) {
        
        XCTAssertFalse(success, @"Failure");
        XCTAssertNil(authToken, @"Auth token is nil");
        XCTAssertNotNil(error, @"There Should be an error because you have nothing in the password feild");
        
        [login fulfill];
    }];
    
    // Then
    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
        XCTAssertNil(error);
    }];
}

- (void)test_invalid_user_login {
    // IF
    NSString *user = @"jivetesting10@gmail.com";
    NSString *password = @"testing12";
    XCTestExpectation *login = [self expectationWithDescription:@"login"];
    
    // When
    JCAuthClient *authClient = [JCAuthClient new];
    [authClient loginWithUsername:user password:password completion:^(BOOL success, NSDictionary *authToken, NSError *error) {
        
        XCTAssertFalse(success, @"Failure");
        XCTAssertNil(authToken, @"Auth token is nil");
        XCTAssertNotNil(error, @"You should have an error becasue you have an invalid username");
        
        [login fulfill];
    }];
    
    // Then
    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
        XCTAssertNil(error);
    }];
}

- (void)test_invalid_password_login {
    // IF
    NSString *user = @"jivetesting10";
    NSString *password = @"asdfjl";
    XCTestExpectation *login = [self expectationWithDescription:@"login"];
    
    // When
    JCAuthClient *authClient = [JCAuthClient new];
    [authClient loginWithUsername:user password:password completion:^(BOOL success, NSDictionary *authToken, NSError *error) {
        
        XCTAssertFalse(success, @"Failure");
        XCTAssertNil(authToken, @"Auth token is nil");
        XCTAssertNotNil(error, @"You should have a falilure becasue you have the wrong password");
        
        [login fulfill];
    }];
    
    // Then
    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
        XCTAssertNil(error);
    }];
}

@end
