//
//  JCSettingsTableViewControllerTests.m
//  JiveOne
//
//  Created by P Leonard on 4/6/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCMainStoryboardBaseTestCase.h"
#import "JCSettingsTableViewController.h"

#import "JCAppSettings.h"
#import "JCAuthenticationManager.h"

#import "DID.h"
#import "NSString+Additions.h"

@interface JCSettingsTableViewControllerTests : JCMainStoryboardBaseTestCase

@property (nonatomic, strong) JCSettingsTableViewController *vc;

@end

@implementation JCSettingsTableViewControllerTests

- (void)setUp {
    [super setUp];
    
    JCSettingsTableViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"JCSettingsTableViewController"];
    
    id appSettings = OCMClassMock([JCAppSettings class]);
    vc.appSettings = appSettings;
    XCTAssertEqual(appSettings, vc.appSettings, @"App Settings is not the mock app settings");
    
    id authenticationManager = OCMClassMock([JCAuthenticationManager class]);
    vc.authenticationManager = authenticationManager;
    XCTAssertEqual(authenticationManager, vc.authenticationManager, @"Authentication Manager is not the mock authentication manger");
    
    [vc performSelectorOnMainThread:@selector(loadView) withObject:nil waitUntilDone:YES];
    self.vc = vc;
}

- (void)tearDown {
    
    self.vc = nil;
    [super tearDown];
}


@end
