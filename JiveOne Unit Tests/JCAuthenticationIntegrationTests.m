//
//  JCAuthTests.m
//  JiveOne
//
//  Created by P Leonard on 3/24/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "JCAuthClient.h"

@interface JCAuthIntegrationTests : XCTestCase

@end

@implementation JCAuthIntegrationTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testAuth {
    // This is an example of a functional test case.
    
    // IF
    // Define give set of inputs
    NSString *user = @"jivetesting10";
    NSString *password = @"testing12";
    
    // When
    // Do the action being tested
   id result = [self loginWithUserName:user password:password];
    
    // Then
    // Was expected result received.
    XCTAssertNotNil(result, @"No result recevied.");
}


-(id)loginWithUserName:(NSString *)userName password:(NSString *)password
{
    JCAuthClient *client = [JCAuthClient new];
    
    return client;
}

@end
