//
//  JCAuthenticationManagerTests.m
//  JiveOne
//
//  Created by P Leonard on 4/6/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCBaseTestCase.h"
#import "JCUserManager.h"
#import "JCAuthKeychain.h"

#import "PBX.h"
#import "DID.h"

@interface JCUserManager ()

-(instancetype)initWithKeychain:(JCAuthKeychain *)keychain;

@end

@interface JCAuthenticationManagerTests : JCBaseTestCase

@property (nonatomic, strong) JCUserManager *authenticationManager;

@end

@implementation JCAuthenticationManagerTests

-(void)setUp {
    [super setUp];
    id authenticationKeychain = OCMClassMock([JCAuthKeychain class]);
    JCUserManager *authenticationManager = [[JCUserManager alloc] initWithKeychain:authenticationKeychain];
    self.authenticationManager = authenticationManager;
}

-(void)tearDown
{
    self.authenticationManager = nil;
    [super tearDown];
}

@end
