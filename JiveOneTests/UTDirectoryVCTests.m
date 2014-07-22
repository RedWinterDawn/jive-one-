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
#import "JCContactsClient.h"

@interface UTDirectoryVCTests : XCTestCase

@end

@implementation UTDirectoryVCTests

- (JCContactsClient *)createUniqueClientInstance
{
	return [[JCContactsClient alloc] init];
}

- (JCContactsClient *)getSharedClient
{
	return [JCContactsClient sharedClient];
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
	JCContactsClient *s1 = [self getSharedClient];
	XCTAssertEqualObjects(s1, [self getSharedClient]);
}

- (void)testSingletonSharedClientSeparateFromUniqueInstance {
	JCContactsClient *s1 = [self getSharedClient];
	XCTAssertNotEqual(s1, [self createUniqueClientInstance]);
}

- (void)testSingletonReturnsSeparateUniqueInstances {
	JCContactsClient *s1 = [self createUniqueClientInstance];
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

SPEC_BEGIN(DirectoryVCTests)
__block JCDirectoryViewController* directoryVC;

describe(@"DirectoryVC", ^{
    context(@"context", ^{
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
            [directoryVC loadCompanyDirectory];
        });
        it(@"clientEntitiesArray is filled upon load", ^{
            [[directoryVC.clientEntitiesArray shouldNot] beEmpty];
        });
        
        it(@"after favoriting a person, isFavorite == true", ^{
            NSIndexPath *indexpath = [NSIndexPath indexPathForRow:0 inSection:0];
            JCPersonCell *firstCell = (JCPersonCell*)[directoryVC.tableView cellForRowAtIndexPath:indexpath];
            [[firstCell shouldNot] beNil];
            BOOL isFavoriteStart = firstCell.line.isFavorite;
            [firstCell toggleFavoriteStatus:nil];
            
            if(isFavoriteStart == [firstCell.line.isFavorite boolValue]){
                 XCTFail(@"toggleFavoriteStatus should have changed isFavorite from what it was");
            }
                  
        });
    });
});

SPEC_END
