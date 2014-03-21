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
#import "Voicemail.h"
#import "JCOsgiClient.h"
#import "TRVSMonitor.h"
#import <OCMock/OCMock.h>

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

- (void)testVoicemailDelete {
    
    id mockVoiceVC = [OCMockObject niceMockForClass:[JCVoicemailViewController class]];
    [[mockVoiceVC expect] viewDidLoad];
    [mockVoiceVC viewDidLoad];
    [mockVoiceVC verify];
    
    [[mockVoiceVC expect] updateVoicemailData];
    [mockVoiceVC updateVoicemailData];
    [mockVoiceVC verify];
    
    NSMutableArray *voicemailTest = [NSMutableArray arrayWithArray:((JCVoicemailViewController *)mockVoiceVC).voicemails];
    XCTAssertNotNil(voicemailTest, @"voicemails was nil");
    
    XCTAssertNotNil(mockVoiceVC, @"Mock voicemail vc was nil");
    
    
}

@end
