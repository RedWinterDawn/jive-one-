//
//  UTDirectoryVCTests.m
//  JiveOne
//
//  Created by Daniel George on 7/21/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Kiwi/Kiwi.h>
#import "Common.h"
#import "TRVSMonitor.h"
#import "JCAuthenticationManager.h"
#import "JCDirectoryViewController.h"

SPEC_BEGIN(DirecotryVC)
__block JCDirectoryViewController* directoryVC;

describe(@"DirectoryVC", ^{
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
            
            directoryVC = [[UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil] instantiateViewControllerWithIdentifier:@"JCDirectoryViewController"];
        });
        it(@"", ^{
            //TODO: test goes here
        });
    });
});

SPEC_END
