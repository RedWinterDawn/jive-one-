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
#import "JCStartLoginViewController.h"

@interface JCOsgiClientTest : XCTestCase
{
    TRVSMonitor *classMonitor;
}

@end

@implementation JCOsgiClientTest

- (void)setUp
{
    [super setUp];
    if (!classMonitor) {
        classMonitor = [TRVSMonitor monitor];
    }
    
    // test.my.jive.com token for user jivetesting10@gmail.com
    NSString *token = [[JCAuthenticationManager sharedInstance] getAuthenticationToken];
    if ([self stringIsNilOrEmpty:token]) {
        if ([self stringIsNilOrEmpty:[[NSUserDefaults standardUserDefaults] objectForKey:@"authToken"]]) {
            NSString *testToken = @"c8124461-0b9b-473b-a22e-fbf62feffa11";
            [[JCAuthenticationManager sharedInstance] didReceiveAuthenticationToken:testToken];
        }
    }
}

- (void)didLoadWebview:(NSNotification *)notification
{
    UIWebView *webView = (UIWebView *)notification.object;
    [webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.getElementById('username').value = '%@';document.getElementById('password').value = '%@';document.getElementById('go-button').click()", @"jivetesting10@gmail.com", @"testing12"]];
    
}

- (void)didLoggedIn:(NSNotification *)notification
{
    [classMonitor signal];
}

-(BOOL)stringIsNilOrEmpty:(NSString*)aString {
    return !(aString && aString.length);
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}



- (void)testShouldRetrieveMyEntity
{
    TRVSMonitor *monitor = [TRVSMonitor monitor];
    __block NSDictionary* response;
    
    NSString *expectedEmail = @"jivetesting10@gmail.com";
    
    [[JCOsgiClient sharedClient] RetrieveMyEntitity:^(id JSON) {
        response = JSON;
        [monitor signal];
    } failure:^(NSError *err) {
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
    
    NSString *givenChatRoomName = (NSString*)response[@"entries"][0][@"name"];
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
    TRVSMonitor *monitor = [TRVSMonitor monitor];
    __block NSDictionary* response;
    
    NSString *testConversation = @"permanentrooms:896";
    NSString *testMessage = [NSString stringWithFormat:@"Automated Test Message %@", [NSDate date]];
    NSString *testEntity = @"entities:jivetesting10@gmail_com";
    
    [[JCOsgiClient sharedClient] SubmitChatMessageForConversation:testConversation message:testMessage withEntity:testEntity success:^(id JSON) {
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


@end
