//
//  JCSettingsTableViewControllerTests.m
//  JiveOne
//
//  Created by P Leonard on 4/6/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCMainStoryboardBaseTestCase.h"
#import "JCSettingsTableViewController.h"

@interface JCSettingsTableViewControllerTests : JCMainStoryboardBaseTestCase

@property (nonatomic, strong) JCSettingsTableViewController *vc;

@end

@implementation JCSettingsTableViewControllerTests

- (void)setUp {
    [super setUp];
    
    JCSettingsTableViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"JCSettingsTableViewController"];
    
    
    
    
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

@end
