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

//Kiwi
//test whether the UpdateTable method will save a json(mocked) from the api into from core data
SPEC_BEGIN(VoicemailTests)
__block JCVoiceTableViewController* voicemailViewController;



describe(@"Voicemail VC", ^{
    context(@"after being instantiated and authenticated", ^{
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
        });
        
        afterAll(^{ // Occurs once
        });
        
        beforeEach(^{ // Occurs before each enclosed "it"
            //add voicemail programtically for user
//            TRVSMonitor *monitor = [TRVSMonitor monitor];
//            NSURLRequest *request = [NSURLRequest alloc] initWithURL:@"http://10.20.26.141:8880/voicemails/mailbox/0146de22-4cf6-65b5-3be8-006300620001/folders/INBOX";
//            [request setValue:@"@msg0000.WAV" forKey:@"file"];
//            [request setValue:@"msg0000.txt" forKey:@"metadata"];
////            
////            [[JCAuthenticationManager sharedInstance] loginWithUsername:username password:password completed:^(BOOL success, NSError *error) {
////                [monitor signal];
////            }];
//            
//            [monitor wait];
        });
        
        afterEach(^{ // Occurs after each enclosed "it"
        });
        
        //TESTS Begin
        it(@"loads voicemails into view upon instantiation", ^{//instantiation calls loadVoicemails via viewDidLoad
            [voicemailViewController loadVoicemails];
            [[voicemailViewController.voicemails should] beNonNil];
        });
        
        
        it(@"should mark a voicemail as read when play button is pressed on unread voicemail", ^{
            NSIndexPath *indexpath = [NSIndexPath indexPathForRow:0 inSection:0];
            JCVoiceCell *cell = (JCVoiceCell*)[voicemailViewController.tableView cellForRowAtIndexPath:indexpath];
            [[cell.voicemail.read shouldNot] beYes];
            voicemailViewController.selectedCell = cell;
            [voicemailViewController voiceCellPlayTapped:cell];
            
            [[expectFutureValue(theValue([cell.voicemail.read boolValue])) shouldEventually] beYes];
        });
        
    });
});


SPEC_END

