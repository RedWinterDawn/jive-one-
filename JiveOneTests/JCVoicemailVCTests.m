//
//  JCVoicemailVCTests.m
//  JiveOne
//
//  Created by Daniel George on 3/13/14.
//  Edited by Daniel Leonard on 4/10/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "JCVoiceTableViewController.h"
#import "JCAuthenticationManager.h"
#import "JCRESTClient.h"
#import "TRVSMonitor.h"
#import <OCMock/OCMock.h>
#import "Voicemail+Custom.h"

@interface JCVoicemailVCTests : XCTestCase
@property (nonatomic, strong) JCVoiceTableViewController *voicemailViewController;

@end

@implementation JCVoicemailVCTests

- (void)setUp
{
    [super setUp];
    
    // test.my.jive.com token for user jivetesting10@gmail.com
    NSString *token = [[JCAuthenticationManager sharedInstance] getAuthenticationToken];
    if ([self stringIsNilOrEmpty:token]) {
        if ([self stringIsNilOrEmpty:[[NSUserDefaults standardUserDefaults] objectForKey:@"authToken"]]) {
            NSString *testToken = kTestAuthKey;
            NSDictionary *oauth_response = [NSDictionary dictionaryWithObjectsAndKeys:testToken, @"access_token", nil];
            [[JCAuthenticationManager sharedInstance] didReceiveAuthenticationToken:oauth_response];
        }
    }
    
    
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.voicemailViewController = [[UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil] instantiateViewControllerWithIdentifier:@"JCVoicemailViewController"];
//    self.voicemailViewController.tableView = [[UITableView alloc] initWithFrame:CGRectZero];
    [self forceLoadingOfTheView];
    //    self.JCDDVC.tableView.dataSource
}

-(BOOL)stringIsNilOrEmpty:(NSString*)aString {
    return !(aString && aString.length);
}

- (void)forceLoadingOfTheView
{
    XCTAssertNotNil(self.voicemailViewController.tableView, @"tableview is Nil");
}

//A real unit test
//test whether the UpdateTable method will save a json(mocked) from the api into from core data
-(void)testUpdateTableSavesDataToCoreData{
    //mock the client
    id clientMock = [OCMockObject niceMockForClass:[JCRESTClient class]];
    __block TRVSMonitor *monitor = [TRVSMonitor monitor];
    //when retriveVoicemailForEntity is called on client, return a JSON like the server would
    [[clientMock expect] RetrieveVoicemailForEntity:[OCMArg any]
                                            success:[OCMArg checkWithBlock:^BOOL(void (^successBlock)(AFHTTPRequestOperation *, id))
                                                     {
                                                         // Here we capture the success block and execute it with a stubbed response.
                                                         
                                                         //created hardcoded json object as a return object from the server
                                                          NSString *jsonString = @"{\"entries\":[{\"_id\":\"voicemails:2921\",\"lastModified\":1395761052406,\"entity\":\"entities:dgeorge\",\"pbxId\":\"0127d974-f9f3-0704-2dee-000100420001\",\"lineId\":\"0144d212-122f-edbf-5867-000100620002\",\"mailboxId\":\"0144d212-122f-edc0-5867-000100620002\",\"folderId\":\"INBOX\",\"messageId\":\"msg0001\",\"extensionNumber\":\"6006\",\"extensionName\":\"test User\",\"callerId\":\"<15412078581>\",\"length\":5,\"origFile\":\"http://nfsweb/pbx/voicemail/0127d974-f9f3-0704-2dee-000100420001/0144d212-122f-edc0-5867-000100620002/INBOX/msg0001.ulaw\",\"__v\":0,\"read\":false,\"createdDate\":1395158996000,\"file\":\"https://test.my.jive.com/urn/voicemails:2921:file\",\"urn\":\"voicemails:2921\",\"id\":\"voicemails:2921\"}],\"ETag\":\"message_18533\"}";
                                                         
                                                         NSData *responseObject = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
                                                         NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:nil];
                                                         
                                                         //because the method will add the json objects to core data and then populate JCVoicemailViewController.voicemails from core data, we need to make sure only our hard coded json object exists in core data
                                                         [Voicemail MR_truncateAll];
                                                         //now add our hard coded json to core data
                                                         [Voicemail addVoicemails:dictionary[@"entries"] completed:^(BOOL success) {
                                                             [monitor signal];
                                                         }];
                                                         
                                                         [monitor wait];
                                                         successBlock(nil, jsonString);
                                                         
                                                         return YES;
                                                     }]
                                            failure:OCMOCK_ANY];
    //set the client property on voicemail view controller to our mock
    [self.voicemailViewController osgiClient:clientMock];
    
    //voicemail view controller is setup in setup method
    //now call updateVoicemailData which will call RetrieveVoicemailForEntity (because it's mocked we'll get the json string made above)
    [self.voicemailViewController updateVoiceTable];
    //ensure that Retrieve was called indirectly since we made a direct call to updateVoicemailData
    [clientMock verify];
    
    //make sure it saved to core data
   
    XCTAssertTrue([Voicemail MR_findAll].count == 1, @"should be 1 voicemail instead the voicemail count is: %lul", (unsigned long)self.voicemailViewController.voicemails.count);
}




//tests whether loadVoicemails populates view's array of voicemails (which is loaded is from core data)
-(void)testLoadVoicemailLoadsVoicemail{
    TRVSMonitor *monitor = [TRVSMonitor monitor];
    //created hardcoded json object as a return object from the server
    NSString *jsonString = @"{\"entries\":[{\"_id\":\"voicemails:2921\",\"lastModified\":1395761052406,\"entity\":\"entities:dgeorge\",\"pbxId\":\"0127d974-f9f3-0704-2dee-000100420001\",\"lineId\":\"0144d212-122f-edbf-5867-000100620002\",\"mailboxId\":\"0144d212-122f-edc0-5867-000100620002\",\"folderId\":\"INBOX\",\"messageId\":\"msg0001\",\"extensionNumber\":\"6006\",\"extensionName\":\"test User\",\"callerId\":\"<15412078581>\",\"length\":5,\"origFile\":\"http://nfsweb/pbx/voicemail/0127d974-f9f3-0704-2dee-000100420001/0144d212-122f-edc0-5867-000100620002/INBOX/msg0001.ulaw\",\"__v\":0,\"read\":false,\"createdDate\":1395158996000,\"file\":\"https://test.my.jive.com/urn/voicemails:2921:file\",\"urn\":\"voicemails:2921\",\"id\":\"voicemails:2921\"}],\"ETag\":\"message_18533\"}";

    NSData *responseObject = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:nil];

    //because the method will add the json objects to core data and then populate JCVoicemailViewController.voicemails from core data, we need to make sure only our hard coded json object exists in core data
    [Voicemail MR_truncateAll];
    //now add our hard coded json to core data
    [Voicemail addVoicemails:dictionary[@"entries"] completed:^(BOOL success) {
        [monitor signal];
    }];
    
    [monitor wait];
    NSLog(@"Count of items in CoreData: %lu", (unsigned long)[Voicemail MR_findAll].count);

    [self.voicemailViewController loadVoicemails];
    
    //make sure it saved to viewcontroller.voicemails
    NSLog(@"Count of items is: %lu", (unsigned long)self.voicemailViewController.voicemails.count);
    
    NSLog(@"%@",[dictionary description]);
        XCTAssertTrue(self.voicemailViewController.voicemails.count == 1, @"should be 1 voicemail instead the voicemail count is: %lu", (unsigned long)self.voicemailViewController.voicemails.count);
}


@end
