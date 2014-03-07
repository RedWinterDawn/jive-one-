//
//  JCGroupsTests.m
//  JiveOne
//
//  Created by Ethan Parker on 3/6/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "JCAuthenticationManager.h"
#import "JCDirectoryGroupViewController.h"
#import "JCGroupSelectorViewController.h"

@interface JCGroupsTests : XCTestCase

@property (nonatomic, strong) JCDirectoryGroupViewController *directoryGroupViewController;


@end

@implementation JCGroupsTests

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
    
    self.directoryGroupViewController = [[JCDirectoryGroupViewController alloc]initWithStyle:UITableViewStyleGrouped];
    self.directoryGroupViewController.tableView = [[UITableView alloc] initWithFrame:CGRectZero];
    [self forceLoadingOfTheView];
    [self.directoryGroupViewController viewWillAppear:YES];
    
}

-(BOOL)stringIsNilOrEmpty:(NSString*)aString {
    return !(aString && aString.length);
}

- (void)forceLoadingOfTheView
{
    XCTAssertNotNil(self.directoryGroupViewController.tableView, @"tableview is Nil");
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}


- (void)testNumberOfSectionsInTableView {
    
    XCTAssertTrue([self.directoryGroupViewController numberOfSectionsInTableView:self.directoryGroupViewController.tableView] == 3, @"Number of sections in table should be 3");
}

- (void)testArrayOfConacts {
    XCTAssertNotNil(self.directoryGroupViewController.testArray, @"testArray did not get instatiated");
}

@end
