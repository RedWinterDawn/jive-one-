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

- (void)testLoadLocalDirectory {
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil];
    JCDirectoryViewController *JCDirectory = [storyboard instantiateViewControllerWithIdentifier:@"JCDirectoryViewController"];
    [JCDirectory viewDidLoad];
    [JCDirectory.segControl setSelectedSegmentIndex:1];

    [JCDirectory segmentChanged:nil];

    
    XCTAssertNotNil(JCDirectory.clientEntitiesArray, @"Client Entities Array from local contacts did not get instantiated");
    XCTAssertTrue([JCDirectory.clientEntitiesArray count] == 26, @"The array does not have 26 arrays");
    int counter=1;
    
    for (NSMutableArray *oneOfTwentySixArrays in JCDirectory.clientEntitiesArray) {
        
        XCTAssertNotNil(oneOfTwentySixArrays, @"The [%d]th array is nil", counter );
        counter++;
        
        if (oneOfTwentySixArrays.count != 0) {
            NSMutableDictionary *localDictionary = oneOfTwentySixArrays[0];
            
             
            XCTAssertNotNil([localDictionary objectForKey:@"firstName"], @"Dictionary does not contain firstName string");
            XCTAssertNotNil([localDictionary objectForKey:@"lastName"], @"Dictionary does not contain lastName string");
        }
        
    }
    
}

- (void)testLoadCompanyDirectory {
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil];
    JCDirectoryViewController *JCDirectory = [storyboard instantiateViewControllerWithIdentifier:@"JCDirectoryViewController"];
    [JCDirectory viewDidLoad];
    [JCDirectory.segControl setSelectedSegmentIndex:0];
    
    [JCDirectory segmentChanged:nil];
    
    XCTAssertNotNil(JCDirectory.clientEntitiesArray, @"Client Entities Array from company contacts did not get instantiated");
    XCTAssertTrue([JCDirectory.clientEntitiesArray count] == 26, @"The array does not have 26 arrays");
    int counter=1;
    for (NSMutableArray *oneOfTwentySixArrays in JCDirectory.clientEntitiesArray) {
        
        XCTAssertNotNil(oneOfTwentySixArrays, @"The [%d]th array is nil", counter );
        counter++;
        
        if (oneOfTwentySixArrays.count != 0) {
            ClientEntities *testContact = oneOfTwentySixArrays[0];
            
            
            XCTAssertNotNil(testContact.firstName, @"Company contact does not contain firstName string");
            XCTAssertNotNil(testContact.lastName, @"Company contact not contain lastName string");
        }
    }
    
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

