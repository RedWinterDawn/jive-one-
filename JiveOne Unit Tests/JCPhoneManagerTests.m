//
//  JCPhoneManagerTests.m
//  JiveOne
//
//  Created by Robert Barclay on 3/31/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "JCPhoneManager.h"
#import "JCSipManager.h"
#import "JCAppSettings.h"
#import <AFNetworking/AFNetworkReachabilityManager.h>

@interface JCPhoneManager (Private)

@property (nonatomic, strong) JCSipManager *sipManager;
@property (nonatomic, strong) JCAppSettings *appSettings;
@property (nonatomic, strong) AFNetworkReachabilityManager *networkReachabilityManager;

-(instancetype)initWithSipManager:(JCSipManager *)sipManager
                      appSettings:(JCAppSettings *)appSettings
              reachabilityManager:(AFNetworkReachabilityManager *)reachabilityManager;

@end

@interface JCPhoneManagerTests : XCTestCase

@property (nonatomic, strong) id sipHandlerMock;
@property (nonatomic, strong) JCPhoneManager *phoneManager;
@property (nonatomic, strong) id appSettingsMock;
@property (nonatomic, strong) id reachabilityManagerMock;

@end

@implementation JCPhoneManagerTests

- (void)setUp {
    [super setUp];
    
    // Mock the sip handler
    self.sipHandlerMock = OCMClassMock([JCSipManager class]);
    self.appSettingsMock = OCMClassMock([JCAppSettings class]);
    self.reachabilityManagerMock = OCMClassMock([AFNetworkReachabilityManager class]);
    
    // instance and verify that sip handler is the mock sip handler.
    self.phoneManager = [[JCPhoneManager alloc] initWithSipManager:self.sipHandlerMock
                                                       appSettings:self.appSettingsMock
                                               reachabilityManager:self.reachabilityManagerMock];
    
    XCTAssertNotNil(self.phoneManager, @"Phone Manager should not be nil");
    XCTAssertNotNil(self.phoneManager.sipManager, @"Sip Handler should not be nil");
    XCTAssertEqual(self.sipHandlerMock, self.phoneManager.sipManager, @"Sip Handler is not mock sip handler");
}

- (void)tearDown {
    self.sipHandlerMock = nil;
    self.phoneManager = nil;
    [super tearDown];
}

- (void)test_JCPhoneManager_initialization {
    
    JCPhoneManager *phoneManager = self.phoneManager;
    
    // verify storyboarding of phone manger is in place and corrent
    XCTAssertNotNil(phoneManager.storyboardName, @"Phone Manager Storyboard name should not be nil");
    
    // Verify Properties Initial state.
    XCTAssertFalse(phoneManager.isInitialized, @"Phone Manager should not be initialized");
    XCTAssertFalse(phoneManager.isRegistering, @"Phone Manager should not be registering");
    XCTAssertFalse(phoneManager.isRegistered, @"Phone Manager should not be registered");
    XCTAssertFalse(phoneManager.isActiveCall, @"Phone Manager should not be active call");
    XCTAssertFalse(phoneManager.isConferenceCall, @"Phone Manager should not be conference call");
    XCTAssertFalse(phoneManager.isMuted, @"Phone Manager should not be muted");
    XCTAssertTrue(phoneManager.networkType == JCPhoneManagerNoNetwork, @"Phone Manager should have an unknown network");
}

- (void)test_JCPhoneManager_connect_to_line_null
{
    // TODO
}




@end
