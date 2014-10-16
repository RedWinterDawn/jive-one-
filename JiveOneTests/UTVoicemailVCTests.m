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
#import "JCVoicemailClient.h"
#import "TRVSMonitor.h"
#import <OCMock/OCMock.h>
#import "Voicemail+Custom.h"
#import "Kiwi.h"
#import "Common.h"


@interface UTVoicemailVCTests : XCTestCase

@end

@implementation UTVoicemailVCTests

- (JCVoicemailClient *)createUniqueClientInstance
{
	return [[JCVoicemailClient alloc] init];
}

- (JCVoicemailClient *)getSharedClient
{
	return [JCVoicemailClient sharedClient];
}

- (JCAuthenticationManager *)createUniqueAuthManagerInstance
{
	return [[JCAuthenticationManager alloc] init];
}

- (JCAuthenticationManager *)getSharedAuthManager
{
	return [JCAuthenticationManager sharedInstance];
}

#pragma mark - tests

- (void)testSingletonSharedClientCreated {
	XCTAssertNotNil([self createUniqueClientInstance]);
}

- (void)testSingletonUniqueClientInstanceCreated {
	XCTAssertNotNil([self createUniqueClientInstance]);
}

- (void)testSingletonReturnsSameSharedClientTwice {
	JCVoicemailClient *s1 = [self getSharedClient];
	XCTAssertEqualObjects(s1, [self getSharedClient]);
}

- (void)testSingletonSharedClientSeparateFromUniqueInstance {
	JCVoicemailClient *s1 = [self getSharedClient];
	XCTAssertNotEqual(s1, [self createUniqueClientInstance]);
}

- (void)testSingletonReturnsSeparateUniqueInstances {
	JCVoicemailClient *s1 = [self createUniqueClientInstance];
	XCTAssertNotEqual(s1, [self createUniqueClientInstance]);
}

- (void)testSingletonSharedAuthManagerCreated {
	XCTAssertNotNil([self createUniqueAuthManagerInstance]);
}

- (void)testSingletonUniqueAuthManagerInstanceCreated {
	XCTAssertNotNil([self createUniqueAuthManagerInstance]);
}

- (void)testSingletonReturnsSameSharedAuthManagerTwice {
	JCAuthenticationManager *s1 = [self getSharedAuthManager];
	XCTAssertEqualObjects(s1, [self getSharedAuthManager]);
}

- (void)testSingletonSharedAuthManagerSeparateFromUniqueInstance {
	JCAuthenticationManager *s1 = [self getSharedAuthManager];
	XCTAssertNotEqual(s1, [self createUniqueAuthManagerInstance]);
}

- (void)testSingletonReturnsSeparateUniqueAuthManagerInstances {
	JCAuthenticationManager *s1 = [self createUniqueAuthManagerInstance];
	XCTAssertNotEqual(s1, [self createUniqueAuthManagerInstance]);
}


@end




//Kiwi
//test whether the UpdateTable method will save a json(mocked) from the api into from core data
SPEC_BEGIN(VoicemailTests)
__block JCVoiceTableViewController* voicemailViewController;



describe(@"Voicemail VC", ^{
    context(@"", ^{//after being instantiated and authenticated	
		
        beforeAll(^{ // Occurs once
            NSString *token = [[JCAuthenticationManager sharedInstance] getAuthenticationToken];
            if ([Common stringIsNilOrEmpty:token]) {
                if ([Common stringIsNilOrEmpty:[[NSUserDefaults standardUserDefaults] objectForKey:@"authToken"]]) {
                    NSString *username = @"jivetesting12@gmail.com";
                    NSString *password = @"testing12";
                    TRVSMonitor *monitor = [TRVSMonitor monitor];
                    
                    [[JCAuthenticationManager sharedInstance] loginWithUsername:username password:password completed:^(BOOL success, NSError *error) {
                        [monitor signal];
                    }];
                    
                    [monitor wait];
                }
            }
            
            voicemailViewController = [[UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil] instantiateViewControllerWithIdentifier:@"JCVoiceTableViewController"];
            [voicemailViewController loadVoicemails];
        });
        
        afterAll(^{ // Occurs once
        });
        
        beforeEach(^{ // Occurs before each enclosed "it"
            //add voicemail programtically for user
            TRVSMonitor *monitor = [TRVSMonitor monitor];
            NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"voicemails" ofType:@"json"];
            NSString *content = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
            NSData *responseObject = [content dataUsingEncoding:NSUTF8StringEncoding];
            NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:nil];
            
            [Voicemail addVoicemails:dictionary mailboxUrl:@"" completed:^(BOOL success) {
                [monitor signal];
            }];
            [monitor wait];
            
        });
        
        afterEach(^{ // Occurs after each enclosed "it"
        });
		
#pragma mark - helper methods
		
		
		
		
        
        //TESTS Begin
        it(@"loads voicemails array into view upon instantiation", ^{//instantiation calls loadVoicemails via viewDidLoad
            [[voicemailViewController.voicemails should] beNonNil];
        });
        
        it(@"voicemail objects should have non nil attributes", ^{
            if(voicemailViewController.voicemails.count>0){
                Voicemail *first = voicemailViewController.voicemails[0];
                if(first){
                    [[first.callerId shouldNot] beNil];
                    //            [[first.callerIdNumber shouldNot] beNil];
                    [[first.duration shouldNot] beNil];
                    [[first.jrn shouldNot] beNil];
                    [[first.mailboxUrl shouldNot] beNil];
                    [[first.timeStamp shouldNot] beNil];
                    //            [[first.transcription shouldNot] beNil];
                    //            [[first.transcriptionPercent shouldNot] beNil];
                    [[first.url_changeStatus shouldNot] beNil];
                    [[first.url_download shouldNot] beNil];
                    //            [[first.url_pbx shouldNot] beNil];
                    [[first.url_self shouldNot] beNil];
                    //            [[first.voicemailId shouldNot] beNil];
                    //            [[first.voicemail shouldNot] beNil];
                }
            }
        });
        
        it(@"should mark a voicemail as read when play button is pressed on unread voicemail", ^{
            NSIndexPath *indexpath = [NSIndexPath indexPathForRow:0 inSection:0];
            JCVoiceCell *cell = (JCVoiceCell*)[voicemailViewController.tableView cellForRowAtIndexPath:indexpath];
            if(cell){
                if(![cell.voicemail.read boolValue]){
                    [[theValue([cell.voicemail.read boolValue])shouldNot] beYes];
                    voicemailViewController.selectedCell = cell;
                    [voicemailViewController voiceCellPlayTapped:cell];
                    
                    [[expectFutureValue(theValue([cell.voicemail.read boolValue])) shouldEventually] beYes];
                }
            }
        });
        
        it(@"should mark email for deletion when deleted", ^{
            
            NSIndexPath *indexpath = [NSIndexPath indexPathForRow:0 inSection:0];
            JCVoiceCell *cell = (JCVoiceCell*)[voicemailViewController.tableView cellForRowAtIndexPath:indexpath];
            if(cell){
                [voicemailViewController voiceCellDeleteTapped:indexpath];
                //wait for async task
                [[expectFutureValue(theValue([cell.voicemail.markForDeletion boolValue])) shouldEventually] beYes];
                //            [[cell.voicemail.deleted should] beYes];
            }
        });
        
//        it(@"should delete marked voicemails in background", ^{
//           
//            NSIndexPath *indexpath = [NSIndexPath indexPathForRow:0 inSection:0];
//            JCVoiceCell *cell = (JCVoiceCell*)[voicemailViewController.tableView cellForRowAtIndexPath:indexpath];
//            [voicemailViewController voiceCellDeleteTapped:indexpath];
//            [[expectFutureValue(theValue(cell.voicemail)) shouldEventuallyBeforeTimingOutAfter(5.0)] beNil];
//              
//        });
        
    });
});




SPEC_END



