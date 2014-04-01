//
//  JCVoicemailVCTests.m
//  JiveOne
//
//  Created by Daniel George on 3/13/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "JCVoicemailViewController.h"
#import "JCAuthenticationManager.h"
#import "JCOsgiClient.h"
#import "TRVSMonitor.h"
#import <OCMock/OCMock.h>
#import "Voicemail+Custom.h"

@interface JCVoicemailVCTests : XCTestCase
@property (nonatomic, strong) JCVoicemailViewController * voicemailViewController;

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
            [[JCAuthenticationManager sharedInstance] didReceiveAuthenticationToken:testToken];
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


-(void)testUpdateVoicemailData{
    
    if(!self.voicemailViewController.voicemails){
        self.voicemailViewController.voicemails = [[NSMutableArray alloc] init];
    }
    TRVSMonitor *monitor = [TRVSMonitor monitor];
    __block NSDictionary* json;
    
    //TODO: use OCMock to create NSManagedObject ClientEntity
    ClientEntities *me = [ClientEntities MR_createEntity];
    me.externalId = @"dgeorge";
    
    [[JCOsgiClient sharedClient] RetrieveVoicemailForEntity:me success:^(id JSON) {
        [self.voicemailViewController updateVoicemailData];
        json = JSON;
        [monitor signal];
    } failure:^(NSError *err) {
        NSLog(@"Test failed");
    }];
    [monitor wait];
    
    //get voicemails in core data
    NSArray *array = [Voicemail MR_findAll];
    
    //get number of voicemails retrieved in call to server and stored in array
    NSUInteger jsonVoicemails = self.voicemailViewController.voicemails.count;
    XCTAssertTrue(json.count == array.count, @"Number of voicemails in core data does not match number retrieved by JSON");
    XCTAssertTrue(jsonVoicemails == array.count, @"Number of voicemails in core data does not match number set to voicemails array");
}




//A real unit test
-(void)testUpdateVoicemailDataSavesVoicemail{
    //mock the client
    id clientMock = [OCMockObject niceMockForClass:[JCOsgiClient class]];
    
  
    
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
                                           [Voicemail addVoicemails:dictionary[@"entries"]];

                                           successBlock(nil, jsonString);
                                           
                                           return YES;
                                       }]
                              failure:OCMOCK_ANY];

    //set the client property on voicemail view controller to our mock
    [self.voicemailViewController osgiClient:clientMock];
    
    //voicemail view controller is setup in setup method
    //now call updateVoicemailData which will call RetrieveVoicemailForEntity (because it's mocked we'll get the json string made above)
    [self.voicemailViewController updateVoicemailData];
    
    //ensure that Retrieve was called indirectly since we made a direct call to updateVoicemailData
    [clientMock verify];
    
    //make sure it saved to viewcontroller.voicemails
    XCTAssertTrue(self.voicemailViewController.voicemails.count == 1, @"should be one voicemail...from the hard coded json string above");
}






//:voicemail should be fetched from server and saved in core data
- (void)testVoicemailFetch {
    
    
    id mockVoiceVC = [OCMockObject niceMockForClass:[JCVoicemailViewController class]];
    [[mockVoiceVC expect] updateVoicemailData];//should be called in viewDidLoad
    [(JCVoicemailViewController*)mockVoiceVC viewDidLoad];
    [mockVoiceVC verify];
    
//    [[mockVoiceVC expect] updateVoicemailData];
//    [mockVoiceVC updateVoicemailData];
//    [mockVoiceVC verify];
    
    NSMutableArray *voicemailTest = ((JCVoicemailViewController *)mockVoiceVC).voicemails;
    XCTAssertNotNil(voicemailTest, @"voicemails was nil");
    
    XCTAssertNotNil(mockVoiceVC, @"Mock voicemail vc was nil");
    
    
}

@end
