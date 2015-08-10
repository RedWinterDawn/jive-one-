//
//  JCTransferViewControllerTests.m
//  JiveOne
//
//  Created by Robert Barclay on 3/31/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCPhoneManagerBaseTestCase.h"

// Controllers
#import "JCPhoneDialerViewController.h"

// Managers
#import "JCPhoneManager.h"
#import "JCAuthenticationManager.h"

// Views
#import "JCFormattedPhoneNumberLabel.h"

// Objects
#import "Line.h"
#import "OutgoingCall.h"
#import "JCPhoneBookTestDataFactory.h"

@interface JCPhoneDialerViewController ()

@property (nonatomic, strong) AFNetworkReachabilityManager *networkingReachabilityManager;

@end

@interface JCTransferViewControllerTests : JCPhoneManagerBaseTestCase <JCPhoneDialerViewControllerDelegate>
{
    XCTestExpectation *_expectation;
}

@property (nonatomic, strong) JCPhoneDialerViewController *vc;

@end

@implementation JCTransferViewControllerTests

- (void)setUp {
    [super setUp];
    
    JCPhoneDialerViewController *vc = [self.phoneManager.storyboard instantiateViewControllerWithIdentifier:@"warmTransferModal"];
    
    id phoneManager = OCMClassMock([JCPhoneManager class]);
    vc.phoneManager = phoneManager;
    XCTAssertEqual(phoneManager, vc.phoneManager, @"Phone Manager is not the mock phone manger");
    
    id appSettings = OCMClassMock([JCAppSettings class]);
    vc.appSettings = appSettings;
    XCTAssertEqual(appSettings, vc.appSettings, @"App Settings is not the mock app settings");
    
    JCPhoneBook *phoneBook = [JCPhoneBookTestDataFactory loadTestPhoneBook];
    vc.phoneBook = phoneBook;
    XCTAssertEqual(phoneBook, vc.phoneBook, @"Phone Book is not the mock address book");
    
    id networkReachabilityManager = OCMClassMock([AFNetworkReachabilityManager class]);
    vc.networkingReachabilityManager = networkReachabilityManager;
    XCTAssertEqual(networkReachabilityManager, vc.networkingReachabilityManager, @"Reachability Manager is not the mock reachability Manager");
    
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

- (void)test_JCTransferViewController_storyboard_initialization
{
    XCTAssertNotNil(self.vc, @"View not initiated properly");
    //XCTAssertTrue([self.vc isKindOfClass:[JCPhoneDialerViewController class]], @"View controller should be kind of class: %@", [JCPhoneDialerViewController class]);
    XCTAssertNotNil(self.vc.view, @"View should not be nil");
    XCTAssertNotNil(self.vc.collectionView, @"Collection view should not be nil");
    //XCTAssertNotNil(self.vc.formattedPhoneNumberLabel, @"Formatted Phone Number Label should not be nil");
    XCTAssertEqual(self.vc.formattedPhoneNumberLabel.delegate, self.vc, @"The Formatted Phone Number delegate should equal the vc");
    XCTAssertNotNil(self.vc.collectionView.dataSource, @"Collection view should have a dataSource");
    XCTAssertEqual(self.vc.collectionView.dataSource, self.vc, @"The Collection view dataSorce should equal the view");
    XCTAssertNotNil(self.vc.collectionView.delegate, @"Collection view should have a delegate");
    XCTAssertEqual(self.vc.collectionView.delegate, self.vc, @"The Collection view delegate should equal the view");
    XCTAssertNotNil(self.vc.callButton, @"Call Button should not be nil");
    XCTAssertNotNil(self.vc.backspaceButton, @"Backspace Button should not be nil");
    XCTAssertNotNil(self.vc.plusLongPressGestureRecognizer, @"Plus Long Press Gesture Recongizer should not be nil");
    XCTAssertNotNil(self.vc.clearLongPressGestureRecognizer, @"Clear Long Press Gesture Recongizer should not be nil");
}

#pragma mark - Number Pad Tests -

-(void)test_numPad_keyPress
{
    // Given
    self.vc.formattedPhoneNumberLabel.dialString = nil;
    UIButton *button = [[UIButton alloc] init];
    button.tag = 5;
    
    // When
    [self.vc numPadPressed:button];
    
    // Then
    NSString *dialString = self.vc.formattedPhoneNumberLabel.dialString;
    XCTAssertTrue([dialString isEqualToString:@"5"]);
}

-(void)test_numPad_longKeyPress
{
    // Given
    self.vc.formattedPhoneNumberLabel.dialString = nil;
    
    // When -> Simulate a long press
    UILongPressGestureRecognizer *r= self.vc.plusLongPressGestureRecognizer;
    r.state = UIGestureRecognizerStateBegan;
    [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
    r.state = UIGestureRecognizerStateChanged;
    [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
    r.state = UIGestureRecognizerStateEnded;
    [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
    [r reset];
    
    // Then
    NSString *dialString = self.vc.formattedPhoneNumberLabel.dialString;
    XCTAssertTrue([dialString isEqualToString:@"+"]);
}

#pragma mark - Initiate Call Tests -

-(void)test_dial_withPhoneNumber
{
    // Given
    self.vc.delegate = self;
    _expectation = [self expectationWithDescription:@"dial"];
    self.vc.formattedPhoneNumberLabel.dialString = @"1234";
    NSString *jrn = @"jrn:line::jive:01471162-f384-24f5-9351-000100420001:014a5955-b837-e8d0-ab9a-000100620001";
    Line *line = [Line MR_findFirstByAttribute:NSStringFromSelector(@selector(jrn)) withValue:jrn];
    OCMStub([self.vc.authenticationManager line]).andReturn(line);
    
    // When
    [self.vc initiateCall:self.vc.callButton];
    
    [self waitForExpectationsWithTimeout:1 handler:^(NSError *error) {
        XCTAssertNil(error, @"expectation not fullfiled ");
    }];
}

-(void)test_cancel
{
    // Given
    self.vc.delegate = self;
    _expectation = [self expectationWithDescription:@"cancel"];
    
    [self.vc cancel:nil];
    
    [self waitForExpectationsWithTimeout:1 handler:^(NSError *error) {
        XCTAssertNil(error, @"expectation not fullfiled ");
    }];
}

-(void)phoneDialerViewController:(JCPhoneDialerViewController *)controller shouldDialNumber:(id<JCPhoneNumberDataSource>)number
{
    XCTAssertTrue([number.dialableNumber isEqualToString:@"1234"], @"dial string does not match");
    XCTAssertTrue((controller = self.vc), @"controllers do not match");
    if ([_expectation.description isEqualToString:@"dial"]) {
        [_expectation fulfill];
    }
    else
    {
        XCTFail(@"Should not have been called here if we are not dialing");
    }
}

-(void)shouldCancelPhoneDialerViewController:(JCPhoneDialerViewController *)controller
{
    XCTAssertTrue((controller = self.vc), @"controllers do not match");
    if ([_expectation.description isEqualToString:@"cancel"]) {
        [_expectation fulfill];
    }
    else
    {
        XCTFail(@"Should not have been called here if we are not dialing");
    }
}

@end
