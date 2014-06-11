//
//  JCOsgiClientTest.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 2/19/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "JCRESTClient.h"
#import "TRVSMonitor.h"
#import "JCAuthenticationManager.h"
#import <OCMock/OCMock.h>
#import "Common.h"
#import "JCLoginViewController.h"
#import "PersonEntities+Custom.h"
#import "Voicemail+Custom.h"
#import "Company.h"


@interface JCOsgiClientTest : XCTestCase

@property (nonatomic, strong) JCLoginViewController *loginViewController;

@end

@implementation JCOsgiClientTest
{
    NSString *barName;
    NSString *barConversation;
}

- (void)setUp
{
    [super setUp];
    
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.loginViewController = [[UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil] instantiateViewControllerWithIdentifier:@"JCLoginViewController"];
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
    
    [[TRVSMonitor monitor] signal];
}



- (void)testShouldRetrieveMyEntity
{
    NSString *expectedEmail = @"jivetesting13@gmail.com";
    NSString *expectedEntityId = @"entities:jivetesting13@gmail_com";
    TRVSMonitor *monitor = [TRVSMonitor monitor];

    
    id mockClient = [OCMockObject niceMockForClass:[JCRESTClient class]];
    [[mockClient expect] RetrieveClientEntitites:[OCMArg checkWithBlock:^BOOL(void (^successBlock)(AFHTTPRequestOperation *, id))
                                                 {
                                                     
                                                     //created hardcoded json object as a return object from the server
                                                     NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"entities" ofType:@"json"];
                                                     NSString *content = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
                                                     NSData *responseObject = [content dataUsingEncoding:NSUTF8StringEncoding];
                                                     NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:nil];
                                                     XCTAssertNotNil(dictionary, @"Could not parse JSON object into NSDictionary");
                                                     //because the method will add the json objects to core data and then populate JCVoicemailViewController.voicemails from core data, we need to make sure only our hard coded json object exists in core data
                                                     [PersonEntities MR_truncateAll];
                                                     //now add our hard coded json to core data
                                                     [PersonEntities addEntities:dictionary[@"entries"] me:expectedEntityId completed:^(BOOL success) {
                                                         [monitor signal];
                                                     }];
                                                     
                                                     [monitor wait];
                                                     
                                                     successBlock(nil, content);

                                                     return YES;
                                                     
                                                 }] failure:OCMOCK_ANY];
  
    [self.loginViewController setClient:mockClient];
    [self.loginViewController fetchEntities];
    
    [mockClient verify];
    
    PersonEntities *me = [PersonEntities MR_findFirstByAttribute:@"me" withValue:[NSNumber numberWithBool:YES]];
    XCTAssertNotNil(me, @"Should have returned my entity");
    XCTAssertEqualObjects(me.email, expectedEmail, @"Expected email and acquired email are different");
}

- (void)testShouldRetrieveMyCompany
{
    //[self testShouldRetrieveMyEntity];
    NSString *expectedCompanyId = @"companies:jive";
    NSString *expectedCompanyName = @"Jive Communications, Inc.";
    
    
    id mockClient = [OCMockObject niceMockForClass:[JCRESTClient class]];

    [[mockClient expect] RetrieveMyCompany:expectedCompanyId :[OCMArg checkWithBlock:^BOOL(void (^successBlock)(AFHTTPRequestOperation *, id))
                                                  {
                                                      
                                                      //created hardcoded json object as a return object from the server
                                                      
                                                      NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"companies" ofType:@"json"];
                                                      NSString *content = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
                                                      NSData *responseObject = [content dataUsingEncoding:NSUTF8StringEncoding];
                                                      NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:nil];
                                                      XCTAssertNotNil(dictionary, @"Could not parse JSON object into NSDictionary");
                                                      
                                                      [Company MR_truncateAll];
                                                      
                                                      NSManagedObjectContext *localContext = [NSManagedObjectContext MR_contextForCurrentThread];
                                                      Company *company = [Company MR_createInContext:localContext];
                                                      company.lastModified = dictionary[@"lastModified"];
                                                      company.pbxId = dictionary[@"pbxId"];
                                                      company.timezone = dictionary[@"timezone"];
                                                      company.name = dictionary[@"name"];
                                                      company.urn = dictionary[@"urn"];
                                                      company.companyId = dictionary[@"id"];
                                                      
                                                      [localContext MR_saveToPersistentStoreAndWait];
                                                      
                                                      successBlock(nil, content);
                                                      
                                                      return YES;
                                                      
                                                      
                                                  }] failure:OCMOCK_ANY];
    
    [self.loginViewController setClient:mockClient];
    [self.loginViewController fetchCompany];
    
    [mockClient verify];

    //PersonEntities *me = [PersonEntities MR_findFirstByAttribute:@"me" withValue:[NSNumber numberWithBool:YES]];
    //XCTAssertNotNil(me, @"Should have returned my entity");
    
    Company *company = [Company MR_findFirst];
    XCTAssertNotNil(company, @"Should have returned my company");   
    XCTAssertEqualObjects(company.name, expectedCompanyName, @"Expected company name and acquired name are different");
}

- (void)testShouldRetrieveConversations
{
    
    id mockClient = [OCMockObject niceMockForClass:[JCRESTClient class]];
    TRVSMonitor *monitor = [TRVSMonitor monitor];
    
    [[mockClient expect] RetrieveConversations:[OCMArg checkWithBlock:^BOOL(void (^successBlock)(AFHTTPRequestOperation *, id))
                                                               {
                                                                   
                                                                   //created hardcoded json object as a return object from the server
                                                                   NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"conversation" ofType:@"json"];
                                                                   NSString *content = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
                                                                   NSData *responseObject = [content dataUsingEncoding:NSUTF8StringEncoding];
                                                                   NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:nil];
                                                                   XCTAssertNotNil(dictionary, @"Could not parse JSON object into NSDictionary");
                                                                   
                                                                   [ConversationEntry MR_truncateAll];
                                                                   [Conversation MR_truncateAll];
                                                                   
                                                                   [Conversation addConversations:dictionary[@"entries"] completed:^(BOOL success) {
                                                                       [monitor signal];
                                                                   }];
                                                                   
                                                                   [monitor wait];
                                                                   successBlock(nil, content);
                                                                   
                                                                   return YES;
                                                                   
                                                                   
                                                               }] failure:OCMOCK_ANY];
    
    [self.loginViewController setClient:mockClient];
    [self.loginViewController fetchConversations];
    
    [mockClient verify];
    
    NSString *expectedChatRoomName = @"The Bar";
    
    Conversation *conversation = [Conversation MR_findFirstByAttribute:@"name" withValue:expectedChatRoomName];
    XCTAssertNotNil(conversation, @"Could not retrieve Conversation: The Bar");
    XCTAssertEqualObjects(conversation.name, expectedChatRoomName, @"Response did not contain correct chat room name");
//       
//    
//    TRVSMonitor *monitor = [TRVSMonitor monitor];
//    __block NSDictionary* response;
//    
//    NSString *expectedChatRoomName = @"The Bar";
//    
//    [[JCOsgiClient sharedClient] RetrieveConversations:^(id JSON) {
//        response = JSON;
//        [monitor signal];
//    } failure:^(NSError *err) {
//        NSLog(@"Error - testShouldRetrieveConversations: %@", [err description]);
//        [monitor signal];
//    }];
//     
//    [monitor wait];
//    
//    XCTAssertNotNil(response, @"Response should not be nil");
//    XCTAssertTrue(([response[@"entries"] count] > 0), @"Response should not have zero entries");
//    
//    
//    NSString *givenChatRoomName;
//    for (NSDictionary *entries in response[@"entries"]) {
//        if (entries[@"name"]) {
//            NSString *groupName = entries[@"name"];
//            if ([groupName isEqualToString:expectedChatRoomName]) {
//                givenChatRoomName = groupName;
//                barConversation = entries[@"id"];
//            }
//        }
//    }
//    XCTAssertEqualObjects(givenChatRoomName, expectedChatRoomName, @"Response did not contain correct chat room name");
}

//- (void)testShouldRequestSocketSession
//{
//    
//    TRVSMonitor *monitor = [TRVSMonitor monitor];
//    __block NSDictionary* response;
//    
//    [[JCOsgiClient sharedClient] RequestSocketSession:^(id JSON) {
//        response = JSON;
//        [monitor signal];
//    } failure:^(NSError *err) {
//        NSLog(@"Error - testShouldRequestSocketSession: %@", [err description]);
//        [monitor signal];
//    }];
//    
//    [monitor wait];
//    
//    XCTAssertNotNil(response, @"Response should not be nil");
//    XCTAssert(response[@"urn"], @"Should Contain URN");
//    XCTAssert(response[@"sessionToken"], @"Should Contain Session Token");
//    XCTAssert(response[@"ws"], @"Should Contain WS");
//}

//- (void)testShouldSubscribeToSocketEventsWithAuthToken
//{
//    TRVSMonitor *monitor = [TRVSMonitor monitor];
//    __block NSDictionary* response;
//    
//    
//    
//    [[JCOsgiClient sharedClient] RequestSocketSession:^(id JSON) {
//        response = JSON;
//        [monitor signal];
//    } failure:^(NSError *err) {
//        NSLog(@"Error - testShouldSubscribeToSocketEventsWithAuthToken: %@", [err description]);
//        [monitor signal];
//    }];
//    
//    [monitor wait];
//    
//    XCTAssertNotNil(response, @"Response should not be nil");
//    XCTAssert(response[@"urn"], @"Should Contain URN");
//    XCTAssert(response[@"sessionToken"], @"Should Contain Session Token");
//    XCTAssert(response[@"ws"], @"Should Contain WS");
//    
//    NSString *token = response[@"token"];
//    NSDictionary* subscriptions = [NSDictionary dictionaryWithObjectsAndKeys:@"(conversations|permanentrooms|groupconversations|adhocrooms):*:entries:*", @"urn", nil];
//    
//    response = nil;
//    
//    [[JCOsgiClient sharedClient] SubscribeToSocketEventsWithAuthToken:token subscriptions:subscriptions success:^(id JSON) {
//        response = JSON;
//        [monitor signal];
//    } failure:^(NSError *err) {
//        NSLog(@"Error - testShouldSubscribeToSocketEventsWithAuthToken: %@", [err description]);
//        [monitor signal];
//    }];
//    
//    [monitor wait];
//    
//    XCTAssertNotNil(response, @"Response should not be nil");
//    XCTAssert(response[@"urn"], @"Should Contain URN");
//    XCTAssert(response[@"subscriptionUrn"], @"Should Contain Subscription URN");
//    XCTAssert(response[@"session"], @"Should Contain Session");
//    
//}

//- (void)testShouldSubmittChatMessageForConversation
//{
//    [self testShouldRetrieveConversations];
//    
//    TRVSMonitor *monitor = [TRVSMonitor monitor];
//    __block NSDictionary* response;
//    
//    NSString *testConversation = barConversation;
//    NSDictionary *testMessage = [NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"Automated Test Message From %@ - %@ - %@", [[UIDevice currentDevice] name], [[UIDevice currentDevice] model], [NSDate date]], @"raw", nil];
//    NSString *testEntity = @"entities:jivetesting13@gmail_com";
//    long long testDate = [Common epochFromNSDate:[NSDate date]];
//    NSString *tempUrn = @"tempUrn";
//    
//    [[JCOsgiClient sharedClient] SubmitChatMessageForConversation:testConversation message:testMessage withEntity:testEntity withTimestamp:testDate withTempUrn:tempUrn success:^(id JSON) {
//        response = JSON;
//        [monitor signal];
//    } failure:^(NSError *err) {
//        NSLog(@"Error - testShouldSubmittChatMessageForConversation: %@", [err description]);
//        [monitor signal];
//    }];
//    
//    [monitor wait];
//    
//    XCTAssertNotNil(response, @"Response should not be nil");
//    
//    NSString *givenMessage = response[@"message"][@"raw"];
//    XCTAssertEqualObjects(givenMessage, testMessage, @"Message received should be same as message posted");
//}

- (void)testShouldRetrieveClientEntities
{
    
    NSString *expectedEntityId = @"entities:jivetesting13@gmail_com";
    id mockClient = [OCMockObject niceMockForClass:[JCRESTClient class]];
    TRVSMonitor *monitor = [TRVSMonitor monitor];
    
    [[mockClient expect] RetrieveClientEntitites:[OCMArg checkWithBlock:^BOOL(void (^successBlock)(AFHTTPRequestOperation *, id))
                                                {
                                                    
                                                    //created hardcoded json object as a return object from the server
                                                    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"entities" ofType:@"json"];
                                                    NSString *content = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
                                                    NSData *responseObject = [content dataUsingEncoding:NSUTF8StringEncoding];
                                                    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:nil];
                                                    XCTAssertNotNil(dictionary, @"Could not parse JSON object into NSDictionary");
                                                    
                                                    XCTAssertNotNil(dictionary, @"Could not parse JSON object into NSDictionary");
                                                    //because the method will add the json objects to core data and then populate JCVoicemailViewController.voicemails from core data, we need to make sure only our hard coded json object exists in core data
                                                    [PersonEntities MR_truncateAll];
                                                    //now add our hard coded json to core data
                                                    [PersonEntities addEntities:dictionary[@"entries"] me:expectedEntityId completed:^(BOOL success) {
                                                        [monitor signal];
                                                    }];
                                                    
                                                    [monitor wait];
                                                    successBlock(nil, content);
                                                    
                                                    return YES;
                                                    
                                                    
                                                }] failure:OCMOCK_ANY];
    
    [self.loginViewController setClient:mockClient];
    [self.loginViewController fetchEntities];
    
    [mockClient verify];
    
    NSArray *entities = [PersonEntities MR_findAll];
    XCTAssertNotNil(entities, @"Should have returned entities");
    XCTAssertTrue(entities.count > 0, @"Response should not have zero entries");
    
//    TRVSMonitor *monitor = [TRVSMonitor monitor];
//    __block NSDictionary* response;
//    
//    [[JCOsgiClient sharedClient] RetrieveClientEntitites:^(id JSON) {
//        response = JSON;
//        [monitor signal];
//    } failure:^(NSError *err) {
//        NSLog(@"Error - testShouldRetrieveClientEntities: %@", [err description]);
//        [monitor signal];
//    }];
//    
//    [monitor wait];
//    
//    XCTAssertNotNil(response, @"Response should not be nil");
//    XCTAssertTrue(([response[@"entries"] count] > 0), @"Response should not have zero entries");
}
/**
 Tests RetrieveVoicemail Method
 This method creates a client entity by saving it to coredata - this is the only way to create a "me" entity when testing becasue we dont login with any specific credentials and thus dont have the [JCOmniPresence me]
 The Test Checks that the response object is not nil, that a random voicemail meta object from the responce object is not nil and, that a specific value for the "context" key is "outgoing"
 */
-(void)testShouldRetrieveVoicemail
{
    id mockClient = [OCMockObject niceMockForClass:[JCRESTClient class]];
    TRVSMonitor *monitor = [TRVSMonitor monitor];
    
    [[mockClient expect] RetrieveVoicemailForEntity:nil success:[OCMArg checkWithBlock:^BOOL(void (^successBlock)(AFHTTPRequestOperation *, id))
                                                  {
                                                      
                                                      //created hardcoded json object as a return object from the server
                                                      NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"voicemails" ofType:@"json"];
                                                      NSString *content = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
                                                      NSData *responseObject = [content dataUsingEncoding:NSUTF8StringEncoding];
                                                      NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:nil];
                                                      
                                                      XCTAssertNotNil(dictionary, @"Could not parse JSON object into NSDictionary");
                                                      //because the method will add the json objects to core data and then populate JCVoicemailViewController.voicemails from core data, we need to make sure only our hard coded json object exists in core data
                                                      [Voicemail MR_truncateAll];
                                                      //now add our hard coded json to core data
                                                      [Voicemail addVoicemails:dictionary[@"entries"] completed:^(BOOL success) {
                                                          [monitor signal];
                                                      }];
                                                      
                                                      [monitor wait];
                                                      successBlock(nil, content);
                                                      
                                                      return YES;
                                                      
                                                      
                                                  }] failure:OCMOCK_ANY];
    
    [self.loginViewController setClient:mockClient];
    [self.loginViewController fetchVoicemails];
    
    [mockClient verify];
    
    NSArray *voicemails = [Voicemail MR_findAll];
    XCTAssertNotNil(voicemails, @"Should have returned entities");
    XCTAssertTrue(voicemails.count > 0, @"Response should not have zero entries");

    
    
//    TRVSMonitor *monitor = [TRVSMonitor monitor];
//    __block NSDictionary* response;
//    NSDictionary* vmail1;
//    
//    NSManagedObjectContext *localContext = [NSManagedObjectContext MR_contextForCurrentThread];
//    PersonEntities *me = [PersonEntities MR_createInContext:localContext];
//    NSString *userId = @"jivetesting10@gmail.com";
//    me.externalId = userId;
//    [localContext MR_saveToPersistentStoreAndWait];
//    
//    [[JCOsgiClient sharedClient] RetrieveVoicemailForEntity:me success:^(id JSON){
//        response = JSON;
//        [monitor signal];
//    }failure:^(NSError *err) {
//        NSLog(@"Error - testShouldRetrieveVoicemail: %@", [err description]);
//        [monitor signal];
//    }];
//    
//    [monitor wait];
//    
//    XCTAssertNotNil(response, @"Response should not be nil");
//    
//    NSArray *entries = response[@"entries"];
//    if (entries && entries.count > 0) {
//        vmail1 = entries[0];
//        XCTAssertNotNil(vmail1, @"Response should not be nil");
//        NSString *expectedContext = @"outgoing";
//        NSString *givenContext = (NSString*)vmail1[@"context"];
//        XCTAssertEqualObjects(givenContext, expectedContext, @"Response did not contain correct context value");
//    }
//    else {
//        XCTAssertTrue(entries.count == 0, @"Should have no entries");
//    }
    
}


@end
