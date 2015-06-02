//
//  JCCoreDataFactoryTests.m
//  JiveOne
//
//  Created by Robert Barclay on 4/6/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCBaseTestCase.h"

#import "User.h"
#import "PBX.h"

@interface JCCoreDataFactoryTests : JCBaseTestCase

@end

@implementation JCCoreDataFactoryTests

- (void)test_core_data_test_data_load {
    
    User *user = [User MR_findFirstByAttribute:NSStringFromSelector(@selector(jiveUserId)) withValue:@"testUser1"];
    XCTAssertNotNil(user, @"testUser1 is nil");
    XCTAssertTrue(user.pbxs.count == 1, @"testUser1 should have only one pbx");
    
    PBX *pbx = user.pbxs.allObjects.firstObject;
    XCTAssertTrue([pbx.name isEqualToString:@"Test User 1 v4 PBX"], @"pbx name incorrect");
    XCTAssertTrue([pbx.jrn isEqualToString:@"jrn:pbx::jive:01471162-f384-24f5-9351-000100420001:pbx~default"]);
    XCTAssertTrue([pbx.pbxId isEqualToString:@"01471162-f384-24f5-9351-000100420001"]);
    XCTAssertFalse(pbx.v5, @"pbx should be v4");
    
    user = [User MR_findFirstByAttribute:NSStringFromSelector(@selector(jiveUserId)) withValue:@"testUser2"];
    XCTAssertNotNil(user, @"testUser2 is nil");
    XCTAssertTrue(user.pbxs.count == 1, @"testUser2 should have only one pbx");
    
    pbx = user.pbxs.allObjects.firstObject;
    XCTAssertTrue([pbx.name isEqualToString:@"Test User 2 PBX"], @"pbx name incorrect");
    XCTAssertTrue([pbx.jrn isEqualToString:@"jrn:pbx::jive:01471162-f384-24f5-9351-000100420002:pbx~default"]);
    XCTAssertTrue([pbx.pbxId isEqualToString:@"01471162-f384-24f5-9351-000100420002"]);
    XCTAssertTrue(pbx.v5, @"pbx should be v5");
    
    user = [User MR_findFirstByAttribute:NSStringFromSelector(@selector(jiveUserId)) withValue:@"testUser3"];
    XCTAssertNotNil(user, @"testUser3 is nil");
    XCTAssertTrue(user.pbxs.count == 2, @"testUser3 should have two pbxs");
}

@end
