//
//  JCRestClientLiveTests.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 6/12/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "JCRESTClient.h"
#import "TRVSMonitor.h"
#import "Common.h"

@interface JCRestClientLiveTests : XCTestCase

@end

@implementation JCRestClientLiveTests
{
    NSString *barName;
    NSString *barConversation;
    int run;
}

- (void)setUp
{
    [super setUp];
    NSString *token = [[JCAuthenticationManager sharedInstance] getAuthenticationToken];
    if ([Common stringIsNilOrEmpty:token]) {
        if ([Common stringIsNilOrEmpty:[[NSUserDefaults standardUserDefaults] objectForKey:@"authToken"]]) {
            NSString *username = @"jivetesting13@gmail.com";
            NSString *password = @"testing12";
            TRVSMonitor *monitor = [TRVSMonitor monitor];
            
            [[JCAuthenticationManager sharedInstance] loginWithUsername:username password:password completed:^(BOOL success, NSError *error) {
                [monitor signal];
            }];
            
            [monitor wait];
        }
    }
    else {
        if (run == 0) {
            [[JCAuthenticationManager sharedInstance] logout:nil];
            [self setUp];
        }
    }
    
    run++;
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testLiveLogin
{
    NSString *username = @"jivetesting13@gmail.com";
    NSString *password = @"testing12";
    
    __block NSDictionary *response = nil;
    TRVSMonitor *monitor = [TRVSMonitor monitor];

    [[JCRESTClient sharedClient] OAuthLoginWithUsername:username password:password success:^(AFHTTPRequestOperation *operation, id JSON) {
        response = (NSDictionary *)JSON;
        [monitor signal];
    } failure:^(AFHTTPRequestOperation *operation, NSError *err) {
        [monitor signal];
    }];

    [monitor wait];

    XCTAssertNotNil(response, @"Should have gotten a respose. Is OAuth Down?");
    XCTAssertNotNil(response[@"access_token"]);
    XCTAssertNotNil(response[@"expires_in"]);
    XCTAssertNotNil(response[@"refresh_token"]);
    XCTAssertNotNil(response[@"type"]);
    XCTAssertNotNil(response[@"username"]);

    XCTAssertNotNil([[JCAuthenticationManager sharedInstance] getAuthenticationToken]);
}

- (void)testShouldRetrieveMyEntity
{
    TRVSMonitor *monitor = [TRVSMonitor monitor];
    __block NSDictionary* response;
    
    NSString *expectedEmail = @"jivetesting13@gmail.com";
    
    [[JCRESTClient sharedClient] RetrieveMyEntitity:^(id operation, id JSON) {
        response = JSON;
        [monitor signal];
    } failure:^(NSError *err, id operation) {
        NSLog(@"Error - testShouldRetrieveMyEntity: %@", [err description]);
        [monitor signal];
    }];
    
    [monitor wait];
    
    XCTAssertNotNil(response, @"Response should not be nil");
    
    NSString *givenEmail = (NSString*)response[@"email"];
    XCTAssertEqualObjects(givenEmail, expectedEmail, @"Response did not contain valid email");
}

- (void)testShouldRetrieveMyCompany
{
    TRVSMonitor *monitor = [TRVSMonitor monitor];
    __block NSDictionary* response;
    
    NSString *testCompany = @"companies:jive";
    NSString *expectedCompanyName = @"Jive Communications, Inc.";
    
    [[JCRESTClient sharedClient] RetrieveMyCompany:testCompany :^(id JSON) {
        response = JSON;
        [monitor signal];
    } failure:^(NSError *err) {
        NSLog(@"Error - testShouldRetrieveMyCompany: %@", [err description]);
        [monitor signal];
    }];
    
    [monitor wait];
    
    XCTAssertNotNil(response, @"Response should not be nil");
    
    NSString *givenCompanyName = (NSString*)response[@"name"];
    XCTAssertEqualObjects(givenCompanyName, expectedCompanyName, @"Response did not contain correct company name");
}

- (void)testShouldRetrieveConversations
{
    TRVSMonitor *monitor = [TRVSMonitor monitor];
    __block NSDictionary* response;
    
    NSString *expectedChatRoomName = @"The Bar";
    
    [[JCRESTClient sharedClient] RetrieveConversations:^(id JSON) {
        response = JSON;
        [monitor signal];
    } failure:^(NSError *err) {
        NSLog(@"Error - testShouldRetrieveConversations: %@", [err description]);
        [monitor signal];
    }];
    
    [monitor wait];
    
    XCTAssertNotNil(response, @"Response should not be nil");
    XCTAssertTrue(([response[@"entries"] count] > 0), @"Response should not have zero entries");
    
    
    NSString *givenChatRoomName;
    for (NSDictionary *entries in response[@"entries"]) {
        if (entries[@"name"]) {
            NSString *groupName = entries[@"name"];
            if ([groupName isEqualToString:expectedChatRoomName]) {
                givenChatRoomName = groupName;
                barConversation = entries[@"id"];
            }
        }
    }
    XCTAssertEqualObjects(givenChatRoomName, expectedChatRoomName, @"Response did not contain correct chat room name");
}

- (void)testShouldRequestSocketSession
{
    
    TRVSMonitor *monitor = [TRVSMonitor monitor];
    __block NSDictionary* response;
    
    [[JCRESTClient sharedClient] RequestSocketSession:^(id JSON) {
        response = JSON;
        [monitor signal];
    } failure:^(NSError *err) {
        NSLog(@"Error - testShouldRequestSocketSession: %@", [err description]);
        [monitor signal];
    }];
    
    [monitor wait];
    
    XCTAssertNotNil(response, @"Response should not be nil");
    XCTAssert(response[@"urn"], @"Should Contain URN");
    XCTAssert(response[@"sessionToken"], @"Should Contain Session Token");
    XCTAssert(response[@"ws"], @"Should Contain WS");
}

- (void)testShouldSubscribeToSocketEventsWithAuthToken
{
    TRVSMonitor *monitor = [TRVSMonitor monitor];
    __block NSDictionary* response;
    
    
    
    [[JCRESTClient sharedClient] RequestSocketSession:^(id JSON) {
        response = JSON;
        [monitor signal];
    } failure:^(NSError *err) {
        NSLog(@"Error - testShouldSubscribeToSocketEventsWithAuthToken: %@", [err description]);
        [monitor signal];
    }];
    
    [monitor wait];
    
    XCTAssertNotNil(response, @"Response should not be nil");
    XCTAssert(response[@"urn"], @"Should Contain URN");
    XCTAssert(response[@"sessionToken"], @"Should Contain Session Token");
    XCTAssert(response[@"ws"], @"Should Contain WS");
    
    NSString *token = response[@"token"];
    NSDictionary* subscriptions = [NSDictionary dictionaryWithObjectsAndKeys:@"(conversations|permanentrooms|groupconversations|adhocrooms):*:entries:*", @"urn", nil];
    
    response = nil;
    
    [[JCRESTClient sharedClient] SubscribeToSocketEventsWithAuthToken:token subscriptions:subscriptions success:^(id JSON) {
        response = JSON;
        [monitor signal];
    } failure:^(NSError *err) {
        NSLog(@"Error - testShouldSubscribeToSocketEventsWithAuthToken: %@", [err description]);
        [monitor signal];
    }];
    
    [monitor wait];
    
    XCTAssertNotNil(response, @"Response should not be nil");
    XCTAssert(response[@"urn"], @"Should Contain URN");
    XCTAssert(response[@"subscriptionUrn"], @"Should Contain Subscription URN");
    XCTAssert(response[@"session"], @"Should Contain Session");
    
}

- (void)testShouldSubmittChatMessageForConversation
{
    TRVSMonitor *monitor = [TRVSMonitor monitor];
    NSString *expectedChatRoomName = @"The Bar";
    __block NSDictionary* response;
    
    [[JCRESTClient sharedClient] RetrieveConversations:^(id JSON) {
        response = JSON;
        [monitor signal];
    } failure:^(NSError *err) {
        NSLog(@"Error - testShouldRetrieveConversations: %@", [err description]);
        [monitor signal];
    }];
    
    [monitor wait];
    
    XCTAssertNotNil(response, @"Response should not be nil");
    XCTAssertTrue(([response[@"entries"] count] > 0), @"Response should not have zero entries");
    
    
    NSString *givenChatRoomName;
    for (NSDictionary *entries in response[@"entries"]) {
        if (entries[@"name"]) {
            NSString *groupName = entries[@"name"];
            if ([groupName isEqualToString:expectedChatRoomName]) {
                givenChatRoomName = groupName;
                barConversation = entries[@"id"];
            }
        }
    }
  
    
    NSString *testConversation = barConversation;
    NSString *expectedEntry = [NSString stringWithFormat:@"Automated Test Message From %@ - %@ - %@", [[UIDevice currentDevice] name], [[UIDevice currentDevice] model], [NSDate date]];
    NSDictionary *testMessage = [NSDictionary dictionaryWithObjectsAndKeys:expectedEntry, @"raw", nil];
    NSString *testEntity = @"entities:jivetesting13@gmail_com";
    long long testDate = [Common epochFromNSDate:[NSDate date]];
    NSString *tempUrn = @"tempUrn";
    
    [[JCRESTClient sharedClient] SubmitChatMessageForConversation:testConversation message:testMessage withEntity:testEntity withTimestamp:testDate withTempUrn:tempUrn success:^(id JSON) {
        response = JSON;
        [monitor signal];
    } failure:^(NSError *err, AFHTTPRequestOperation *operation) {
        NSLog(@"Error - testShouldSubmittChatMessageForConversation: %@", [err description]);
        [monitor signal];
    }];
    
    [monitor wait];
    
    XCTAssertNotNil(response, @"Response should not be nil");
    
    NSString *givenMessage = response[@"message"][@"raw"];
    XCTAssertEqualObjects(givenMessage, expectedEntry, @"Message received should be same as message posted");
}

- (void)testShouldRetrieveClientEntities
{
    TRVSMonitor *monitor = [TRVSMonitor monitor];
    __block NSDictionary* response;
    
    [[JCRESTClient sharedClient] RetrieveClientEntitites:^(id JSON) {
        response = JSON;
        [monitor signal];
    } failure:^(NSError *err) {
        NSLog(@"Error - testShouldRetrieveClientEntities: %@", [err description]);
        [monitor signal];
    }];
    
    [monitor wait];
    
    XCTAssertNotNil(response, @"Response should not be nil");
    XCTAssertTrue(([response[@"entries"] count] > 0), @"Response should not have zero entries");
}
/**
 Tests RetrieveVoicemail Method
 This method creates a client entity by saving it to coredata - this is the only way to create a "me" entity when testing becasue we dont login with any specific credentials and thus dont have the [JCOmniPresence me]
 The Test Checks that the response object is not nil, that a random voicemail meta object from the responce object is not nil and, that a specific value for the "context" key is "outgoing"
 */
-(void)testShouldRetrieveVoicemail
{
    TRVSMonitor *monitor = [TRVSMonitor monitor];
    __block NSDictionary* response;
    NSDictionary* vmail1;
    
    
    [[JCRESTClient sharedClient] RetrieveVoicemailForEntity:nil success:^(id JSON){
        response = JSON;
        [monitor signal];
    }failure:^(NSError *err) {
        NSLog(@"Error - testShouldRetrieveVoicemail: %@", [err description]);
        [monitor signal];
    }];
    
    [monitor wait];
    
    XCTAssertNotNil(response, @"Response should not be nil");
    
    NSArray *entries = response[@"entries"];
    if (entries && entries.count > 0) {
        vmail1 = entries[0];
        XCTAssertNotNil(vmail1, @"Response should not be nil");
        NSString *expectedContext = @"outgoing";
        NSString *givenContext = (NSString*)vmail1[@"context"];
        XCTAssertEqualObjects(givenContext, expectedContext, @"Response did not contain correct context value");
    }
    else {
        XCTAssertTrue(entries.count == 0, @"Should have no entries");
    }
    
}

@end
