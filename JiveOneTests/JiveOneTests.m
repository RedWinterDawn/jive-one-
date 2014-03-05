//
//  JiveOneTests.m
//  JiveOneTests
//
//  Created by Eduardo Gueiros on 2/13/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "JCOsgiClient.h"
#import "TRVSMonitor.h"
#import "JCAuthenticationManager.h"
#import "JCDirectoryViewController.h"

@interface JiveOneTests : XCTestCase

@end

@implementation JiveOneTests

- (void)setUp
{
    [super setUp];
    
    // test.my.jive.com token for user jivetesting10@gmail.com
    if (![[JCAuthenticationManager sharedInstance] getAuthenticationToken]) {
        NSString *testToken = @"6e4cd798-fb5c-434f-874c-7b2aa1aeeeca";
        [[JCAuthenticationManager sharedInstance] didReceiveAuthenticationToken:testToken];
    }
    
    // Put setup code here. This method is called before the invocation of each test method in the class.
    //Fire login event
    
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}


- (void)testRetrieveAccountInformation {
    __block NSDictionary *json;
    
    TRVSMonitor *monitor = [TRVSMonitor monitor];
    
    JCOsgiClient *client = [JCOsgiClient sharedClient];
    
    [client RetrieveMyEntitity:^(id JSON) {
        json = JSON;
        [monitor signal];
        
    } failure:^(NSError *err) {
        XCTFail(@"Retrieve My Company method has failed");
    }];
    
    [monitor waitWithTimeout:5];
    
    NSString *name = [[json objectForKey:@"name"] objectForKey:@"firstLast"];
    NSString *companyUrl = [json objectForKey:@"company"];
    XCTAssertEqualObjects(name, @"Jive Testing 10", @"Wrong name");
    
    [client RetrieveMyCompany:companyUrl:^(id JSON) {
        json = JSON;
        [monitor signal];
    } failure:^(NSError *err) {
        NSLog(@"%@", err);
    }];
    
    [monitor waitWithTimeout:5];
    
     XCTAssertEqualObjects([json objectForKey:@"name"], @"Jive Communications, Inc.", @"Company name doesn't match");
}



- (void)testLogout {
    
    [[JCAuthenticationManager sharedInstance] logout:nil];
    
    KeychainItemWrapper *wrapper = [[KeychainItemWrapper alloc] initWithIdentifier:kJiveAuthStore accessGroup:nil];
    NSString* tokenFromKeychain = [wrapper objectForKey:(__bridge id)(kSecAttrAccount)];
    NSString* tokenFromUserDefaults = [[NSUserDefaults standardUserDefaults] objectForKey:@"authToken"];
    
    XCTAssertEqual(tokenFromKeychain, @"", @"Token From Keychain Should Have Cleared");
    XCTAssertNil(tokenFromUserDefaults, @"Token From UserDefaults Should Have Cleared");
    
}

@end

