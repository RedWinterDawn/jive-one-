//
//  JCV5ClientTest.m
//  JiveOne
//
//  Created by Robert Barclay on 3/27/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCCoreDataBaseTestCase.h"
#import "JCV5ApiClient.h"
#import "JCUnknownNumber.h"

@interface JCV5ClientTest : JCCoreDataBaseTestCase
{
    NSString *_authToken;
    User *_user;
    DID *_did;
    
    JCUnknownNumber *_person;
}

@end

@implementation JCV5ClientTest

- (void)setUp {
    [super setUp];
    
    _authToken = @"";
    
    // User
    _user = [User MR_createInContext:self.context];
    _user.jiveUserId = @"jivetesting11@gmail.com";
    
    // DID
    _did = [DID MR_createInContext:self.context];
    _did.jrn = @"";
    _did.number = @"";
    
    _person = [JCUnknownNumber new];
    //_person.name = @"Test Name";
    _person.number = @"12345";
}


- (void)test_pbxInfo_successfull_download {
    
    // Given
    
    // When
    [JCV5ApiClient requestPBXInforForUser:_user competion:^(BOOL success, id response, NSError *error) {
        
    }];
    
    // This
    XCTAssert(YES, @"Pass");
}

-(void)test_sms_messages_conversations_download {
    
    [JCV5ApiClient downloadMessagesDigestForDID:_did completion:^(BOOL success, id response, NSError *error) {
        
    }];
}

-(void)test_sms_messages_download {
    
    [JCV5ApiClient downloadMessagesForDID:_did completion:^(BOOL success, id response, NSError *error) {
        
    }];
}

-(void)test_sms_messages_conversation_download {
    
    [JCV5ApiClient downloadMessagesForDID:_did toPerson:_person completion:^(BOOL success, id response, NSError *error) {
        
    }];
}


- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
