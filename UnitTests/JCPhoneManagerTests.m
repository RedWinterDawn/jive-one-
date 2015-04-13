//
//  JCPhoneManagerTests.m
//  JiveOne
//
//  Created by Robert Barclay on 3/31/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCBaseTestCase.h"
#import <AFNetworking/AFNetworkReachabilityManager.h>

#import "JCPhoneManager.h"
#import "JCSipManager.h"
#import "JCAppSettings.h"
#import "Line.h"
#import "LineConfiguration.h"
#import "JCUnknownNumber.h"
#import "JCPhoneBook.h"

@interface JCPhoneManager (Private)

@property (nonatomic, strong) JCSipManager *sipManager;
@property (nonatomic, strong) JCAppSettings *appSettings;
@property (nonatomic, strong) AFNetworkReachabilityManager *networkReachabilityManager;

-(instancetype)initWithSipManager:(JCSipManager *)sipManager
                      appSettings:(JCAppSettings *)appSettings
                        phoneBook:(JCPhoneBook *)phoneBook
              reachabilityManager:(AFNetworkReachabilityManager *)reachabilityManager;

-(void)connectToLine:(Line *)line completion:(CompletionHandler)completion;

-(void)dialPhoneNumber:(NSString *)dialString usingLine:(Line *)line type:(JCPhoneManagerDialType)dialType completion:(CompletionHandler)completion;

@end

@interface JCPhoneManagerTests : JCBaseTestCase

@property (nonatomic, strong) id sipHandlerMock;
@property (nonatomic, strong) JCPhoneManager *phoneManager;
@property (nonatomic, strong) id appSettingsMock;
@property (nonatomic, strong) id reachabilityManagerMock;
@property (nonatomic, strong) JCPhoneBook *phoneBook;

@end

@implementation JCPhoneManagerTests

- (void)setUp
{
    [super setUp];
    
    // Mock the sip handler
    self.sipHandlerMock = OCMClassMock([JCSipManager class]);
    self.appSettingsMock = OCMClassMock([JCAppSettings class]);
    self.reachabilityManagerMock = OCMClassMock([AFNetworkReachabilityManager class]);
    
    self.phoneBook = [[JCPhoneBook alloc] init];
    
    // instance and verify that sip handler is the mock sip handler.
    self.phoneManager = [[JCPhoneManager alloc] initWithSipManager:self.sipHandlerMock
                                                       appSettings:self.appSettingsMock
                                                         phoneBook:self.phoneBook
                                               reachabilityManager:self.reachabilityManagerMock];
    
    XCTAssertNotNil(self.phoneManager, @"Phone Manager should not be nil");
    
    XCTAssertNotNil(self.phoneManager.sipManager, @"Sip Handler should not be nil");
    XCTAssertEqual(self.sipHandlerMock, self.phoneManager.sipManager, @"Sip Handler is not mock sip handler");
    
    XCTAssertNotNil(self.phoneManager.appSettings, @"Sip Handler should not be nil");
    XCTAssertEqual(self.appSettingsMock, self.phoneManager.appSettings, @"App Settings is not mock app settings");
    
    XCTAssertNotNil(self.phoneManager.networkReachabilityManager, @"Sip Handler should not be nil");
    XCTAssertEqual(self.reachabilityManagerMock, self.phoneManager.networkReachabilityManager, @"Reachability Manager is not mock reachanbility manager");
}

- (void)tearDown
{
    self.sipHandlerMock = nil;
    self.appSettingsMock = nil;
    self.reachabilityManagerMock = nil;
    self.phoneManager = nil;
    [super tearDown];
}

- (void)test_JCPhoneManager_initialization
{
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

#pragma mark - Connetion Tests -

- (void)test_JCPhoneManager_connectToLine_connectedWifi_notWifiOnly
{
    // Given
    NSManagedObjectContext *context = self.context;
    Line *line = [Line MR_createInContext:context];
    line.lineConfiguration = [LineConfiguration MR_createInContext:context];
    AFNetworkReachabilityManager *reachabilityManagerMock = self.reachabilityManagerMock;
    
    OCMStub([self.appSettingsMock isWifiOnly]).andReturn(false);
    OCMStub([reachabilityManagerMock isReachable]).andReturn(true);
    OCMStub([reachabilityManagerMock isReachableViaWWAN]).andReturn(false);
    OCMStub([reachabilityManagerMock networkReachabilityStatus]).andReturn(JCPhoneManagerWifiNetwork);
    
    // When
    [self.phoneManager connectToLine:line completion:NULL];
    
    // Then
    OCMVerify([self.sipHandlerMock registerToLine:line]);
}

// TODO Write test cases for the rest of the connect to line scenarios.

#pragma mark - Dialing -

- (void)test_JCPhoneManager_dialPhoneNumber
{
    // Given
    Line *line = [Line MR_createInContext:self.context];
    NSString *number = @"5555555555";
    JCUnknownNumber *unknownNumber = [JCUnknownNumber unknownNumberWithNumber:number];
    JCPhoneManagerDialType type = JCPhoneManagerSingleDial;
    JCSipManager *sipManagerMock = self.sipHandlerMock;
    
    OCMStub([sipManagerMock line]).andReturn(line);
    OCMStub([sipManagerMock isRegistered]).andReturn(true);
    
    [self.phoneManager dialPhoneNumber:unknownNumber usingLine:line type:type completion:NULL];
    
    OCMVerify([sipManagerMock makeCall:unknownNumber videoCall:NO error:[OCMArg anyObjectRef]]);
}

// TODO Write test cases for the rest of the dial string scenarios.


@end
