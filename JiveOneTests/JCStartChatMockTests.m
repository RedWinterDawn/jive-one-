//
//  JCStartChatMockTests.m
//  JiveOne
//
//  Created by Ethan Parker on 3/12/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "JCAuthenticationManager.h"
#import "JCDirectoryDetailViewController.h"
#import "JCConversationDetailViewController.h"
#import "JCDirectoryViewController.h"
#import "JCDirectoryGroupViewController.h"
#import <OCMock/OCMock.h>

@interface JCStartChatMockTests : XCTestCase

@property (nonatomic, strong) JCDirectoryDetailViewController *directoryGroupViewController;


@end

@implementation JCStartChatMockTests

- (void)setUp
{
    [super setUp];
    
    // test.my.jive.com token for user jivetesting10@gmail.com
    NSString *token = [[JCAuthenticationManager sharedInstance] getAuthenticationToken];
    if ([self stringIsNilOrEmpty:token]) {
        if ([self stringIsNilOrEmpty:[[NSUserDefaults standardUserDefaults] objectForKey:@"authToken"]]) {
            NSString *testToken = kTestAuthKey;
            [[JCAuthenticationManager sharedInstance] didReceiveAuthenticationToken:testToken];
        }
    }
    // Put setup code here; it will be run once, before the first test case.
}

-(BOOL)stringIsNilOrEmpty:(NSString*)aString {
    return !(aString && aString.length);
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}

- (void)testJCDirectoryDetailViewControllerMock {
    
    id mockDVC = [OCMockObject mockForClass:[JCDirectoryViewController class]];
    //id mockDDVC = [OCMockObject mockForClass:[JCDirectoryDetailViewController class]];
    //id mockDirectoryGroupVC = [OCMockObject mockForClass:[JCDirectoryGroupViewController class]];
    //id mockConversationDetailVC = [OCMockObject mockForClass:[JCConversationDetailViewController class]];
    
    [[mockDVC expect] viewDidLoad];
    [mockDVC viewDidLoad];
    [mockDVC verify];
    
//    [[mockDVC expect] segmentChanged:nil];
//    [mockDVC segmentChanged:nil];
//    [mockDVC verify];
    
    
    
   // NSArray *arrayForTest = [NSArray arrayWithArray:((JCDirectoryViewController *)mockDVC).clientEntitiesArray];
    
   // XCTAssertNotNil(arrayForTest, @"Mock clientEntitiesArray was nil");
    
    
   // [[[mockDVC stub] andReturnValue:0] segmentChanged:0];
    
    // make a mock of the VC that's being used here and try to return a value of this
    
    
    
    
    //- this was breaking because I think you need to "verify" an actual method from that class, right now we're making a mock VC to allow checking for NotNil
    
    XCTAssertNotNil(mockDVC, @"Mock VC DirectoryDetailVC was nil");
    //XCTAssertNotNil(mockDDVC, @"Mock VC DirectoryDetailVC was nil");
    //XCTAssertNotNil(mockDirectoryGroupVC, @"Mock VC DirectoryGroupVC was nil");
    //XCTAssertNotNil(mockConversationDetailVC, @"Mock VC DirectoryGroupVC was nil");
    
    
}

@end
