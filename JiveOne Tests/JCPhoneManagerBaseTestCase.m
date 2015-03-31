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
    
    JCPhoneManager *phoneManager = [[JCPhoneManager alloc] init];
    XCTAssertNotNil(phoneManager.storyboardName, @"Phone Manager Storyboard name should not be nil");
    XCTAssertNotNil(phoneManager.storyboard, @"Storyboard should not be nil");
    self.phoneManager = phoneManager;
    
    id mockSipHandler = OCMClassMock([JCSipManager class]);
    phoneManager.sipManager = mockSipHandler;
}

- (void)tearDown {
    self.phoneManager = nil;
    [super tearDown];
}

- (void)test_phone_manager_storyboard
{
    
}

@end
