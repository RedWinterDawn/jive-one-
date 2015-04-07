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

@end
