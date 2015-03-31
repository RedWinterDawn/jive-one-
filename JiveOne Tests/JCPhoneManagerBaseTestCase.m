//
//  JCPhoneManagerBaseTestCase.m
//  JiveOne
//
//  Created by Robert Barclay on 3/31/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCPhoneManagerBaseTestCase.h"

@implementation JCPhoneManagerBaseTestCase

- (void)setUp {
    [super setUp];
    
    // Mock the sip handler
    id mockSipHandler = OCMClassMock([JCSipManager class]);
    
    // instance and verify that sip handler is the mock sip handler.
    JCPhoneManager *phoneManager = [[JCPhoneManager alloc] initWithSipManager:mockSipHandler];
    XCTAssertEqual(mockSipHandler = phoneManager.sipManager, @"Sip Handler is not mock sip handler");
    
    // verify storyboarding of phone manger is in place and corrent
    XCTAssertNotNil(phoneManager.storyboardName, @"Phone Manager Storyboard name should not be nil");
    XCTAssertNotNil(phoneManager.storyboard, @"Storyboard should not be nil");
    self.phoneManager = phoneManager;
}

- (void)tearDown {
    self.phoneManager = nil;
    [super tearDown];
}

- (void)test_phone_manager_storyboard
{
    
}

@end
