//
//  JCSettingsTableViewControllerTests.m
//  JiveOne
//
//  Created by P Leonard on 4/6/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCMainStoryboardBaseTestCase.h"
#import "JCSettingsTableViewController.h"

#import "JCAppSettings.h"
#import "JCAuthenticationManager.h"

#import "PBX.h"
#import "DID.h"
#import "NSString+Additions.h"

@interface JCSettingsTableViewControllerTests : JCMainStoryboardBaseTestCase

@property (nonatomic, strong) JCSettingsTableViewController *vc;

@end

@implementation JCSettingsTableViewControllerTests

- (void)setUp {
    [super setUp];
    
    JCSettingsTableViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"JCSettingsTableViewController"];
    
    id appSettings = OCMClassMock([JCAppSettings class]);
    vc.appSettings = appSettings;
    XCTAssertEqual(appSettings, vc.appSettings, @"App Settings is not the mock app settings");
    
    id authenticationManager = OCMClassMock([JCAuthenticationManager class]);
    vc.authenticationManager = authenticationManager;
    XCTAssertEqual(authenticationManager, vc.authenticationManager, @"Authentication Manager is not the mock authentication manger");
    
    [vc performSelectorOnMainThread:@selector(loadView) withObject:nil waitUntilDone:YES];
	self.vc = vc;
}

- (void)tearDown {
    self.vc = nil;
    [super tearDown];
}

- (void)test_smsDefaultLineDisplay
{
    // Given
    NSString *jrn = @"jrn:pbx::jive:01471162-f384-24f5-9351-000100420001:did:014885d6-1526-8b77-a111-000100420001";
    DID *did = [DID MR_findFirstByAttribute:NSStringFromSelector(@selector(jrn)) withValue:jrn];
    OCMStub([self.vc.authenticationManager did]).andReturn(did);
    NSString *expectedResponse = did.formattedNumber;
    
    // When
    [self.vc.view setNeedsLayout];
    [self.vc.view layoutIfNeeded];
    
    // Then
    NSString *string = self.vc.smsUserDefaultNumber.text;
    XCTAssertTrue([string isEqualToString:expectedResponse], @"DId not get expected phone number %@ %@",string, expectedResponse);
}

//- (void)test_smsDefaultLineDisplay_not_visible
//{
//    // Given
//    NSString *jrn = @"jrn:pbx::jive:01471162-f384-24f5-9351-000100420005:pbx~default";
//    PBX *pbx = [PBX MR_findFirstByAttribute:NSStringFromSelector(@selector(jrn)) withValue:jrn];
//    OCMStub([self.vc.authenticationManager pbx]).andReturn(pbx);
//    
//    //When
//    [self.vc viewWillAppear:NO];
//        
//   //Then
//    XCTAssertNotNil(self.vc, @"Your viewcontroller is missing");
//    XCTAssertNotNil(pbx, @"PBX is nil");
//    XCTAssertFalse(pbx.smsEnabled,@"sms Enabled");
//    
//    
//    BOOL hidden = [self.vc cellIsHidden:self.vc.defaultDIDCell];
//    XCTAssertTrue(hidden, @"The DIDCell should be hidden");
//    
//}
//
//- (void)test_smsDefaultLineDisplay_visible
//{
//    // Given
//    NSString *jrn = @"jrn:pbx::jive:01471162-f384-24f5-9351-000100420055:pbx~default";
//    PBX *pbx = [PBX MR_findFirstByAttribute:NSStringFromSelector(@selector(jrn)) withValue:jrn];
//    OCMStub([self.vc.authenticationManager pbx]).andReturn(pbx);
//    
//    //When
//    [self.vc viewWillAppear:NO];
//    
//    //Then
//    XCTAssertNotNil(self.vc, @"Your viewcontroller is missing");
//    XCTAssertNotNil(pbx, @"PBX is nil");
//    XCTAssertTrue(pbx.smsEnabled,@"sms Enabled");
//    XCTAssertTrue(self.vc.defaultDIDCell.hidden, @"The DIDCell should be hidden");
//    
//}
//



@end
