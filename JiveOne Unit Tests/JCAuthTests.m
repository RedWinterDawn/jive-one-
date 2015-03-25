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


@interface UnitTests : XCTestCase

@end

@implementation UnitTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testAuth {
    // IF
    // Define give set of inputs
    NSString *user = @"jivetesting10";
    NSString *password = nil;
    
    // When
    // Do the action being tested
    
    id crap = [self loginWithUserName:user password:password];
    
    // Then
    // Was expected result received.
    XCTAssertNotNil(crap, @"No result recevied.");
}

-(id)loginWithUserName:(NSString *)userName password:(NSString *)password
{
    JCAuthClient *client = [JCAuthClient new];
    
    [client loginWithUsername:userName password:password completed:^(BOOL success, NSError *error) {
    
    }];
    return client;
}

@end
