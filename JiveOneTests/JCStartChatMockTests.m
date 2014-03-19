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
    
    
    id mockDDVC = [OCMockObject mockForClass:[JCDirectoryDetailViewController class]];
    id mockDirectoryGroupVC = [OCMockObject mockForClass:[JCDirectoryGroupViewController class]];
   
    
    id mockDVC = [OCMockObject niceMockForClass:[JCDirectoryViewController class]];
    [[mockDVC expect] viewDidLoad];
    [mockDVC viewDidLoad];
    [mockDVC verify];
    
    [[mockDVC expect] segmentChanged:nil];
    [mockDVC segmentChanged:nil];
    [mockDVC verify];
    
    [[[mockDVC stub] andReturnValue:0] segmentChanged:0];
    
    NSArray *arrayForTest = [NSArray arrayWithArray:((JCDirectoryViewController *)mockDVC).clientEntitiesArray];
    XCTAssertNotNil(arrayForTest, @"Mock clientEntitiesArray was nil");
    
   //- this was breaking because I think you need to "verify" an actual method from that class, right now we're making a mock VC to allow checking for NotNil - NOPE! Don't need to verify! In fact if you leave verify out, all it will do is falsely pass!
    
    XCTAssertNotNil(mockDVC, @"Mock VC DirectoryDetailVC was nil");
    XCTAssertNotNil(mockDDVC, @"Mock VC DirectoryDetailVC was nil");
    XCTAssertNotNil(mockDirectoryGroupVC, @"Mock VC DirectoryGroupVC was nil");
   
    
    
}

@end
