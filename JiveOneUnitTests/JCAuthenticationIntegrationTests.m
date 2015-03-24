//
//  JCAuthenticationTests.m
//  JiveOne
//
//  Created by P Leonard on 3/24/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "JCAuthenticationClient.h"

@interface JCAuthenticationIntegrationTests : XCTestCase

@end

@implementation JCAuthenticationIntegrationTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    XCTAssert(YES, @"Pass");
    
    // Setup
    // Define give set of inputs
    NSString *user = @"bob";
    NSString *password = @"1234";
    
    // Action
    // Do the action being tested
   id result = [self loginWithUserName:user password:password];
    
    // Verify
    // Was expected result received.
//    XCTAssertNotNil(result, @"No result recevied.");
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

-(id)loginWithUserName:(NSString *)userName password:(NSString *)password
{
    JCAuthenticationClient *client = [JCAuthenticationClient new];
    
    return client;
}

@end
