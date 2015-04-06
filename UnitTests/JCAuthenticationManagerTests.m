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
    
}

-(void)test_did_noDIDsForPBX
{
    
}

-(void)test_did_pbxHasDids_hasDefault
{
    
}

-(void)test_did_pbxHasDids_noDefault
{
    // Given
    NSString *jrn = @"jrn:pbx::jive:01471162-f384-24f5-9351-000100420001:did:014885d6-1526-8b77-a111-000100420001";
    PBX *pbx = [PBX MR_findFirstByAttribute:NSStringFromSelector(@selector(jrn)) withValue:jrn];
    id authenticationManagerMock = OCMPartialMock(self.authenticationManager);
    OCMStub([authenticationManagerMock pbx]).andReturn(pbx);
    
    // TODO: figure out which should be the first object did.
    
    // When
    DID *did = ((JCAuthenticationManager *)authenticationManagerMock).did;
    
    // Then
    OCMVerify([authenticationManagerMock pbx]);
               
    // TODO: write more asserts around did.
}

@end
