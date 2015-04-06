//
//  JCPhoneManagerBaseTestCase.m
//  JiveOne
//
//  Created by Robert Barclay on 3/31/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCPhoneManagerBaseTestCase.h"

@interface JCPhoneManager ()

-(instancetype)initWithSipManager:(JCSipManager *)sipManager
                      appSettings:(JCAppSettings *)appSettings
              reachabilityManager:(AFNetworkReachabilityManager *)reachabilityManager;

@end


@implementation JCPhoneManagerBaseTestCase

- (void)setUp {
    [super setUp];
    
    // instance and verify that sip handler is the mock sip handler.
    JCPhoneManager *phoneManager = [[JCPhoneManager alloc] initWithSipManager:nil appSettings:nil reachabilityManager:nil];
    
    // verify storyboarding of phone manger is in place and correct
    XCTAssertNotNil(phoneManager.storyboardName, @"Phone Manager Storyboard name should not be nil");
    XCTAssertNotNil(phoneManager.storyboard, @"Storyboard should not be nil");
    self.phoneManager = phoneManager;
}

- (void)tearDown {
    self.phoneManager = nil;
    [super tearDown];
}

@end
