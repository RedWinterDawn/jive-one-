//
//  JiveOneTests.m
//  JiveOneTests
//
//  Created by Eduardo Gueiros on 2/13/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "JCOsgiClient.h"

@interface JiveOneTests : XCTestCase

@end

@implementation JiveOneTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    //Fire login event
    
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample
{
    XCTFail(@"No implementation for \"%s\"", __PRETTY_FUNCTION__);
}

- (void)testRetrieveAccountInformation{
    __block NSString *companyUrl;
    __block NSString *name;
    
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    
    JCOsgiClient *client = [JCOsgiClient sharedClient];
    [client RetrieveMyEntitity:^(id JSON) {
        name = [JSON objectForKey:@"name"];
        
        XCTAssertEqualObjects(name, @"Daniel George", @"Wrong name");
        companyUrl = [JSON objectForKey:@"company"];
        
         dispatch_semaphore_signal(sema);
        
    } failure:^(NSError *err) {
        XCTFail(@"Retrieve My Company method has failed");
    }];
    
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    dispatch_semaphore_t sema2 = dispatch_semaphore_create(0);
    
    [client RetrieveMyCompany:companyUrl:^(id JSON) {
        
        XCTAssertEqualObjects([JSON objectForKey:@"company"], @"Jive Communications, Inc", @"Company name doesn't match");
        
        dispatch_semaphore_signal(sema2);

        
    } failure:^(NSError *err) {
        NSLog(@"%@", err);
    }];
    dispatch_semaphore_wait(sema2, DISPATCH_TIME_FOREVER);
    
}

@end

