//
//  JCOsgiClientTest.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 2/19/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "JCOsgiClient.h"
#import "TRVSMonitor.h"
#import "JCAuthenticationManager.h"
#import "Common.h"


@interface JCOsgiClientTest : XCTestCase

@end

@implementation JCOsgiClientTest
{
    NSString *barName;
    NSString *barConversation;
}

- (void)setUp
{
    [super setUp];
    
//    NSString *token = [[JCAuthenticationManager sharedInstance] getAuthenticationToken];
//    if ([self stringIsNilOrEmpty:token]) {
//        if ([self stringIsNilOrEmpty:[[NSUserDefaults standardUserDefaults] objectForKey:@"authToken"]]) {
            NSString *testToken = kTestAuthKey;
    NSDictionary *oauth_response = [NSDictionary dictionaryWithObjectsAndKeys:testToken, @"access_token", nil];
            [[JCAuthenticationManager sharedInstance] didReceiveAuthenticationToken:oauth_response];
//        }
//    }
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
    
    [[TRVSMonitor monitor] signal];
}



- (void)testShouldRetrieveMyEntity
{
    TRVSMonitor *monitor = [TRVSMonitor monitor];
    __block NSDictionary* response;
    
    NSString *expectedEmail = @"jivetesting13@gmail.com";
    
    [[JCOsgiClient sharedClient] RetrieveMyEntitity:^(id JSON, id operation) {
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
    
    [[JCOsgiClient sharedClient] RetrieveMyCompany:testCompany :^(id JSON) {
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
    
    [[JCOsgiClient sharedClient] RetrieveConversations:^(id JSON) {
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
    
    [[JCOsgiClient sharedClient] RequestSocketSession:^(id JSON) {
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
    
    
    
    [[JCOsgiClient sharedClient] RequestSocketSession:^(id JSON) {
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
    
    [[JCOsgiClient sharedClient] SubscribeToSocketEventsWithAuthToken:token subscriptions:subscriptions success:^(id JSON) {
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
    [self testShouldRetrieveConversations];
    
    TRVSMonitor *monitor = [TRVSMonitor monitor];
    __block NSDictionary* response;
    
    NSString *testConversation = barConversation;
    NSDictionary *testMessage = [NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"Automated Test Message From %@ - %@ - %@", [[UIDevice currentDevice] name], [[UIDevice currentDevice] model], [NSDate date]], @"raw", nil];
    NSString *testEntity = @"entities:jivetesting13@gmail_com";
    long long testDate = [Common epochFromNSDate:[NSDate date]];
    NSString *tempUrn = @"tempUrn";
    
    [[JCOsgiClient sharedClient] SubmitChatMessageForConversation:testConversation message:testMessage withEntity:testEntity withTimestamp:testDate withTempUrn:tempUrn success:^(id JSON) {
        response = JSON;
        [monitor signal];
    } failure:^(NSError *err) {
        NSLog(@"Error - testShouldSubmittChatMessageForConversation: %@", [err description]);
        [monitor signal];
    }];
    
    [monitor wait];
    
    XCTAssertNotNil(response, @"Response should not be nil");
    
    NSString *givenMessage = response[@"message"][@"raw"];
    XCTAssertEqualObjects(givenMessage, testMessage, @"Message received should be same as message posted");
}

- (void)testShouldRetrieveClientEntities
{
    TRVSMonitor *monitor = [TRVSMonitor monitor];
    __block NSDictionary* response;
    
    [[JCOsgiClient sharedClient] RetrieveClientEntitites:^(id JSON) {
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
    
    NSManagedObjectContext *localContext = [NSManagedObjectContext MR_contextForCurrentThread];
    PersonEntities *me = [PersonEntities MR_createInContext:localContext];
    NSString *userId = @"jivetesting10@gmail.com";
    me.externalId = userId;
    [localContext MR_saveToPersistentStoreAndWait];
    
    [[JCOsgiClient sharedClient] RetrieveVoicemailForEntity:me success:^(id JSON){
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
