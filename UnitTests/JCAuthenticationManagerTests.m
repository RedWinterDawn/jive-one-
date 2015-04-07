//
//  JCAuthenticationManagerTests.m
//  JiveOne
//
//  Created by P Leonard on 4/6/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCBaseTestCase.h"
#import "JCAuthenticationManager.h"
#import "JCAuthenticationKeychain.h"

#import "PBX.h"
#import "DID.h"

@interface JCAuthenticationManager ()

-(instancetype)initWithKeychain:(JCAuthenticationKeychain *)keychain;

@end

@interface JCAuthenticationManagerTests : JCBaseTestCase

@property (nonatomic, strong) JCAuthenticationManager *authenticationManager;

@end

@implementation JCAuthenticationManagerTests

-(void)setUp {
    [super setUp];
    id authenticationKeychain = OCMClassMock([JCAuthenticationKeychain class]);
    JCAuthenticationManager *authenticationManager = [[JCAuthenticationManager alloc] initWithKeychain:authenticationKeychain];
    self.authenticationManager = authenticationManager;
}

-(void)tearDown
{
    self.authenticationManager = nil;
    [super tearDown];
}

-(void)test_did_noPbx
{
     // Given
    id authenticationManagerMock = OCMPartialMock(self.authenticationManager);
    OCMStub([authenticationManagerMock pbx]).andReturn(nil);

    // When
    DID *did = ((JCAuthenticationManager *)authenticationManagerMock).did;
    
     // Then
    OCMVerify([authenticationManagerMock pbx]);
    XCTAssertNil(did, @"did should be nil");
}

-(void)test_did_noDIDsForPBX
{
    // Given
    NSString *jrn = @"jrn:pbx::jive:01471162-f384-24f5-9351-000100420002:pbx~default";
    PBX *pbx = [PBX MR_findFirstByAttribute:NSStringFromSelector(@selector(jrn)) withValue:jrn];
    id authenticationManagerMock = OCMPartialMock(self.authenticationManager);
    OCMStub([authenticationManagerMock pbx]).andReturn(pbx);
    
    // When
    DID *did = ((JCAuthenticationManager *)authenticationManagerMock).did;
    
    // Then
    OCMVerify([authenticationManagerMock pbx]);
    XCTAssertNil(did, @"did should be nil");
    XCTAssertNotNil(pbx, @"The PBX should not be nil");
}

-(void)test_did_pbxHasDids_hasDefault
{
    // Given
    NSString *jrn = @"jrn:pbx::jive:01471162-f384-24f5-9351-000100420003:pbx~default";
    PBX *pbx = [PBX MR_findFirstByAttribute:NSStringFromSelector(@selector(jrn)) withValue:jrn];
    id authenticationManagerMock = OCMPartialMock(self.authenticationManager);
    OCMStub([authenticationManagerMock pbx]).andReturn(pbx);
    NSString *expectedDIDjrn = @"jrn:pbx::jive:01471162-f384-24f5-9351-000100420003:did:014885d6-1526-8b77-a111-000100420031";
    
    // When
    DID *did = ((JCAuthenticationManager *)authenticationManagerMock).did;
    
    // Then
    XCTAssertNotNil(pbx, @"The PBX should not be nil");
     XCTAssertNotNil(did, @"The DID should not be nil");
    XCTAssertTrue([did.jrn isEqualToString:expectedDIDjrn], @"The jrn of the 'DID' did not equil what we exspected %@",did.jrn);
    XCTAssertEqual(did.pbx, pbx, @"The DID did not match the PBX DID ");
    XCTAssertTrue(did.isUserDefault, @"The UserDefault was not set to true on this DID");
    
    
    

}

-(void)test_did_pbxHasDids_noDefault
{
    // Given
    NSString *jrn = @"jrn:pbx::jive:01471162-f384-24f5-9351-000100420001:pbx~default";
    PBX *pbx = [PBX MR_findFirstByAttribute:NSStringFromSelector(@selector(jrn)) withValue:jrn];
    id authenticationManagerMock = OCMPartialMock(self.authenticationManager);
    OCMStub([authenticationManagerMock pbx]).andReturn(pbx);
    
    // TODO: figure out which should be the first object did.
    
    // When
    DID *did = ((JCAuthenticationManager *)authenticationManagerMock).did;
    
    // Then
    OCMVerify([authenticationManagerMock pbx]);
    XCTAssertNotNil(pbx, @"PBX was nil");
    XCTAssertNotNil(did, @"DID was nil");
    XCTAssertFalse(did.isUserDefault, @"The UserDefault was not set to true on this DID");
    // TODO: write more asserts around did.
}

@end
