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
    
    if (![[JCAuthenticationManager sharedInstance] getAuthenticationToken]) {
        NSString *testToken = @"6e4cd798-fb5c-434f-874c-7b2aa1aeeeca";
        [[JCAuthenticationManager sharedInstance] didReceiveAuthenticationToken:testToken];
    }
    
    self.directoryGroupViewController = [[JCDirectoryGroupViewController alloc]initWithStyle:UITableViewStyleGrouped];
    self.directoryGroupViewController.tableView = [[UITableView alloc] initWithFrame:CGRectZero];
    [self forceLoadingOfTheView];
    
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


- (void)testNumberOfSectionsInTableView
{
    
    XCTAssertTrue([self.directoryGroupViewController numberOfSectionsInTableView:self.directoryGroupViewController.tableView] == 3, @"Number of sections in table should be 3");
    
}



@end
