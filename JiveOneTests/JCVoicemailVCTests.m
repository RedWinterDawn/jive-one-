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
    self.voicemailViewController = [[JCVoicemailViewController alloc]initWithStyle:UITableViewStyleGrouped];
    self.voicemailViewController.tableView = [[UITableView alloc] initWithFrame:CGRectZero];
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
    
//    if(!self.voicemailViewController.voicemails){
//        self.voicemailViewController.voicemails = [[NSMutableArray alloc] init];
//    }
    __block id json;
    
    //TODO: use OCMock to create NSManagedObject ClientEntity
    ClientEntities *me = nil;
    
    
    //make a call to osgi client to fill json
    JCOsgiClient *osgi = [JCOsgiClient sharedClient];
    [osgi RetrieveVoicemailForEntity:me success:^(id JSON) {
        json = JSON;
    } failure:^(NSError *err) {
        NSLog(@"Fetch didn't work");
    }];
    
    [self.voicemailViewController updateVoicemailData];
    
    //get voicemails in core data
    NSArray *array = [Voicemail MR_findAll];
    
    //get number of voicemails retrieved in call to server and stored in array
    NSUInteger jsonVoicemails = self.voicemailViewController.voicemails.count;
    XCTAssertTrue(jsonVoicemails == array.count, @"Number of voicemails in core data does not match number retrieved by JSON");
//    XCTAssertTrue(jsonVoicemails == array.count, @"Number of voicemails in core data does not match number set to voicemails array");
}

@end
