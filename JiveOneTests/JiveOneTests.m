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
#import "JCDirectoryViewController.h"

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
    XCTAssertEqualObjects(name, @"Daniel George", @"Wrong name");
    
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
    
    //UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil];
    //JCDirectoryViewController *directoryVC = [storyboard instantiateViewControllerWithIdentifier:@"JCDirectoryViewController"];
    
    [[JCAuthenticationManager sharedInstance] logout:nil];
    
    KeychainItemWrapper *wrapper = [[KeychainItemWrapper alloc] initWithIdentifier:kJiveAuthStore accessGroup:nil];
    NSString* tokenFromKeychain = [wrapper objectForKey:(__bridge id)(kSecAttrAccount)];
    NSString* tokenFromUserDefaults = [[NSUserDefaults standardUserDefaults] objectForKey:@"authToken"];
    
    XCTAssertEqual(tokenFromKeychain, @"", @"Token From Keychain Should Have Cleared");
    XCTAssertNil(tokenFromUserDefaults, @"Token From UserDefaults Should Have Cleared");
    
}

- (void)testGotContactsFromPhone {
    
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
    
    NSArray *allContacts = (__bridge_transfer NSArray *)ABAddressBookCopyArrayOfAllPeople(addressBook);
    NSInteger allContactsCount = [allContacts count];
    
    if (allContactsCount > 0) {
        NSLog(@"Got the contacts");
    } else {
        NSLog(@"Didn't get the contacts");
    }
    
    XCTAssertNotNil(allContacts, @"allContacts should have a few contacts in there, beacuse you're reading this, sadly, it doesn't :(");
    //XCTAssertNil(allContacts, @"allContacts has some stuff in it!!");         - this is the opposite of the above test and it fails!! :)
}

@end

