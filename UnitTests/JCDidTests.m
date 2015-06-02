//
//  JCDidTests.m
//  JiveOne
//
//  Created by P Leonard on 4/6/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCBaseTestCase.h"

#import "DID.h"

@interface JCDidTests : JCBaseTestCase

@end

@implementation JCDidTests

-(void)test_didId {
    
//    // Given
//    NSString *jrn = @"jrn:pbx::jive:01471162-f384-24f5-9351-000100420001:pbx~default";
//    NSString *expectedPbxId = @"01471162-f384-24f5-9351-000100420001";
//    
//    // When
//    PBX *pbx = [PBX MR_findFirstByAttribute:NSStringFromSelector(@selector(jrn)) withValue:jrn];
//    
//    // Thus
//    XCTAssertNotNil(pbx, @"pbx should not be nil");
//    XCTAssertTrue([pbx.jrn isEqualToString:jrn], @"jrn did not match");
//    XCTAssertTrue([pbx.pbxId isEqualToString:expectedPbxId], @"pbx id did not match");
}

@end
