//
//  JiveOneTests.m
//  JiveOneTests
//
//  Created by Eduardo Gueiros on 2/13/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "JCRESTClient.h"
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
    NSString *token = [[JCAuthenticationManager sharedInstance] getAuthenticationToken];
    if ([self stringIsNilOrEmpty:token]) {
        if ([self stringIsNilOrEmpty:[[NSUserDefaults standardUserDefaults] objectForKey:@"authToken"]]) {
            NSString *testToken = kTestAuthKey;
            NSDictionary *oauth_response = [NSDictionary dictionaryWithObjectsAndKeys:testToken, @"access_token", nil];
            [[JCAuthenticationManager sharedInstance] didReceiveAuthenticationToken:oauth_response];
        }
    }
    
    // Put setup code here. This method is called before the invocation of each test method in the class.
    //Fire login event
    
}

-(BOOL)stringIsNilOrEmpty:(NSString*)aString {
    return !(aString && aString.length);
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}


//- (void)testRetrieveAccountInformation {
//    __block NSDictionary *json;
//    
//    TRVSMonitor *monitor = [TRVSMonitor monitor];
//    
//    JCOsgiClient *client = [JCOsgiClient sharedClient];
//    
//    [client RetrieveMyEntitity:^(id JSON, id operation) {
//        json = JSON;
//        [monitor signal];
//        
//    } failure:^(NSError *err, id operation) {
//        XCTFail(@"Retrieve My Company method has failed");
//    }];
//    
//    [monitor waitWithTimeout:5];
//    
//    NSString *name = [[json objectForKey:@"name"] objectForKey:@"firstLast"];
//    NSString *companyUrl = [json objectForKey:@"company"];
//    XCTAssertEqualObjects(name, @"Jive Testing 13", @"Wrong name");
//    
//    [client RetrieveMyCompany:companyUrl:^(id JSON) {
//        json = JSON;
//        [monitor signal];
//    } failure:^(NSError *err) {
//        NSLog(@"%@", err);
//    }];
//    
//    [monitor waitWithTimeout:5];
//    
//     XCTAssertEqualObjects([json objectForKey:@"name"], @"Jive Communications, Inc.", @"Company name doesn't match");
//}



- (void)testLogout {
    
    [[JCAuthenticationManager sharedInstance] logout:nil];
    
    KeychainItemWrapper *wrapper = [[KeychainItemWrapper alloc] initWithIdentifier:kJiveAuthStore accessGroup:nil];
    NSString* tokenFromKeychain = [wrapper objectForKey:(__bridge id)(kSecAttrAccount)];
    NSString* tokenFromUserDefaults = [[NSUserDefaults standardUserDefaults] objectForKey:@"authToken"];
    
    XCTAssertEqual(tokenFromKeychain, @"", @"Token From Keychain Should Have Cleared");
    XCTAssertNil(tokenFromUserDefaults, @"Token From UserDefaults Should Have Cleared");
    
}

@end

