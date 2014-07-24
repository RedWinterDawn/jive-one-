//
//  JiveOneTests.m
//  JiveOneTests
//
//  Created by Eduardo Gueiros on 2/13/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "TRVSMonitor.h"
#import "JCAuthenticationManager.h"
#import "JCDirectoryViewController.h"
#import "Kiwi.h"

@interface UTJiveOneTests : XCTestCase

@end

@implementation UTJiveOneTests

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


- (void)testLogout {
    
    [[JCAuthenticationManager sharedInstance] logout:nil];
    
    KeychainItemWrapper *wrapper = [[KeychainItemWrapper alloc] initWithIdentifier:kJiveAuthStore accessGroup:nil];
    NSString* tokenFromKeychain = [wrapper objectForKey:(__bridge id)(kSecAttrAccount)];
    NSString* tokenFromUserDefaults = [[NSUserDefaults standardUserDefaults] objectForKey:@"authToken"];
    
    XCTAssertEqual(tokenFromKeychain, @"", @"Token From Keychain Should Have Cleared");
    XCTAssertNil(tokenFromUserDefaults, @"Token From UserDefaults Should Have Cleared");
    
}

@end

SPEC_BEGIN(MathSpec)

describe(@"Math", ^{
    it(@"is pretty cool", ^{
        NSUInteger a = 17;
        NSUInteger b = 26;
        [[theValue(a + b) should] equal:theValue(43)];
    });
});

SPEC_END





