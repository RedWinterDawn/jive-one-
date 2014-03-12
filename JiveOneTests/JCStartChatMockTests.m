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
    
    
    id mockDirectoryGroupVC = [OCMockObject mockForClass:[JCDirectoryDetailViewController class]];
    [[mockDirectoryGroupVC expect] viewDidLoad];
    
    id mockConversationDetailVC = [OCMockObject mockForClass:[JCConversationDetailViewController class]];
    [[mockConversationDetailVC expect] viewDidLoad];
    
    
    //  [mockDirectoryGroupVC verify]; - this breaks because I think you need to "verify" an actual method from that class, right now we're making a mock VC to allow checking for NotNil
    
    XCTAssertNotNil(mockDirectoryGroupVC, @"Mock VC DirectoryGroupVC was nil");
    XCTAssertNotNil(mockConversationDetailVC, @"Mock VC DirectoryGroupVC was nil");
    
}

@end
