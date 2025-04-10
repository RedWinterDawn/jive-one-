//
//  JCPbxTests.m
//  JiveOne
//
//  Created by Robert Barclay on 4/6/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCBaseTestCase.h"
#import "PBX.h"

@interface JCPbxTests : JCBaseTestCase

@end

@implementation JCPbxTests

-(void)test_display_name {
    
    // TODO
}

-(void)test_pbx_id {
    
    // Given
    NSString *jrn = @"jrn:pbx::jive:01471162-f384-24f5-9351-000100420001:pbx~default";
    NSString *expectedPbxId = @"01471162-f384-24f5-9351-000100420001";
    
    // When
    PBX *pbx = [PBX MR_findFirstByAttribute:NSStringFromSelector(@selector(jrn)) withValue:jrn];
    
    // Thus
    XCTAssertNotNil(pbx, @"pbx should not be nil");
    XCTAssertTrue([pbx.jrn isEqualToString:jrn], @"jrn did not match");
    XCTAssertTrue([pbx.pbxId isEqualToString:expectedPbxId], @"pbx id did not match");
}

-(void)test_smsEnabled {
    NSString *jrn = @"jrn:pbx::jive:01471162-f384-24f5-9351-000100420001:pbx~default";
    //and the opposite
    NSString *jrnWithoutPermissionsForSMS = @"jrn:pbx::jive:01471162-f384-24f5-9351-000100420005:pbx~default";
    //when
    PBX *pbx = [PBX MR_findFirstByAttribute:NSStringFromSelector(@selector(jrn)) withValue:jrn];
    PBX *pbxNoPermissions = [PBX MR_findFirstByAttribute:NSStringFromSelector(@selector(jrn)) withValue:jrnWithoutPermissionsForSMS];
    
    //Then
    XCTAssertNotNil(pbx,@"The pbx was nil");
    XCTAssertTrue(pbx.smsEnabled, @"This pbx is not smsEnabled");
    
    XCTAssertNotNil(pbxNoPermissions, @"The pbxNoPermissions was nil");
    XCTAssertFalse(pbxNoPermissions.smsEnabled, @"This pbxNoPermissions is smsEnabled and should not be");
}

-(void)test_receiveSMSMessages {
    
    //Given this pbx
    NSString *jrn = @"jrn:pbx::jive:01471162-f384-24f5-9351-000100420001:pbx~default";
    
    //when you have SMS permissions set to true
    PBX *pbx = [PBX MR_findFirstByAttribute:NSStringFromSelector(@selector(jrn)) withValue:jrn];
    
    //Then the pbx should be there and the recive sms flag should be true as long as it is v5
    XCTAssertNotNil(pbx,@"The pbx was nil");
    XCTAssertTrue(pbx.receiveSMSMessages, @"This pbx is not able to receive SMS Messages");
    
    //GIven a pbx
   NSString *jrnNoPermissionsToReciveSMS = @"jrn:pbx::jive:01471162-f384-24f5-9351-000100420005:pbx~default";
   
    //When the PBX does not have permissions
   PBX *pbxNoPermissions = [PBX MR_findFirstByAttribute:NSStringFromSelector(@selector(jrn)) withValue:jrnNoPermissionsToReciveSMS];
    
    //Then the pbx should exsist but the flags should be set to false
    XCTAssertNotNil(pbxNoPermissions, @"The pbx with no permissions was nil");
    XCTAssertFalse(pbxNoPermissions.receiveSMSMessages, @"This pbx is not able to receive SMS Messages");
}

-(void)test_sendSMSMessages {
    
    NSString *jrn = @"jrn:pbx::jive:01471162-f384-24f5-9351-000100420001:pbx~default";
    
    NSString *jrnNoPermissions = @"jrn:pbx::jive:01471162-f384-24f5-9351-000100420005:pbx~default";
    //when
    PBX *pbx = [PBX MR_findFirstByAttribute:NSStringFromSelector(@selector(jrn)) withValue:jrn];
    PBX *pbxNoPermissions = [PBX MR_findFirstByAttribute:NSStringFromSelector(@selector(jrn)) withValue:jrnNoPermissions];
    
    //Then
    XCTAssertNotNil(pbx,@"The pbx was nil");
    XCTAssertTrue(pbx.sendSMSMessages, @"This pbx is not able to send SMS Messages");
    
    XCTAssertNotNil(pbxNoPermissions,@"The pbx with no permissions was nil");
    XCTAssertFalse(pbxNoPermissions.sendSMSMessages, @"This pbx with no permission is able to send SMS Messages and shouldn't");
}

@end
