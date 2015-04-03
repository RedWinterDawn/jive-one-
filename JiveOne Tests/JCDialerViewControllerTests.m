//
//  JCDialerViewControllerTests.m
//  JiveOne
//
//  Created by Robert Barclay on 3/31/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCMainStoryboardBaseTestCase.h"

// Libraries
#import <MagicalRecord/NSManagedObject+MagicalRecord.h>
#import <UIKit/UIGestureRecognizerSubclass.h>

// Controllers
#import "JCDialerViewController.h"

// Managers
#import "JCPhoneManager.h"
#import "JCAuthenticationManager.h"

// Views
#import "JCFormattedPhoneNumberLabel.h"

// Objects
#import "JCAddressBook.h"
#import "Line.h"
#import "OutgoingCall.h"
#import "JCAddressBookTestDataFactory.h"


@interface JCPhoneManager ()

-(void)dialNumber:(NSString *)dialString usingLine:(Line *)line type:(JCPhoneManagerDialType)dialType completion:(CompletionHandler)completion;

@end

@interface JCAddressBook ()

- (instancetype)initWithPeople:(NSSet *)people numbers:(NSSet *)numbers;

@end

@interface JCDialerViewController (Private)

@property (nonatomic, strong) JCAuthenticationManager *authenticationManager;
@property (nonatomic, strong) AFNetworkReachabilityManager *networkingReachabilityManager;
@property (nonatomic, strong) NSManagedObjectContext *context;

@end

@interface JCDialerViewControllerTests : JCMainStoryboardBaseTestCase

@property (nonatomic, strong) JCDialerViewController *vc;

@end

@implementation JCDialerViewControllerTests

- (void)setUp {
    [super setUp];
    
    JCDialerViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"JCDialerViewController"];
    vc.context = self.context;
    
    id phoneManager = OCMClassMock([JCPhoneManager class]);
    vc.phoneManager = phoneManager;
    XCTAssertEqual(phoneManager, vc.phoneManager, @"Phone Manager is not the mock phone manger");
    
    id appSettings = OCMClassMock([JCAppSettings class]);
    vc.appSettings = appSettings;
    XCTAssertEqual(appSettings, vc.appSettings, @"App Settings is not the mock app settings");
    
    // Load Test Address Book Data
    NSDictionary *addressBookData = [JCAddressBookTestDataFactory loadTestAddessBookData];
    NSMutableSet *people  = [addressBookData objectForKey:kJCAddressBookPeople];
    NSMutableSet *numbers = [addressBookData objectForKey:kJCAddressBookNumbers];
    JCAddressBook *addressBook = [[JCAddressBook alloc] initWithPeople:people numbers:numbers];
    vc.sharedAddressBook = addressBook;
    XCTAssertEqual(addressBook, vc.sharedAddressBook, @"Address Book is not the mock address book");
    
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

-(void)test_storyboard_initialization
{
    XCTAssertNotNil(self.vc, @"View not initiated properly");
    XCTAssertTrue([self.vc isKindOfClass:[JCDialerViewController class]], @"View controller should be kind of class: %@", [JCDialerViewController class]);
    XCTAssertNotNil(self.vc.view, @"View should not be nil");
    XCTAssertNotNil(self.vc.collectionView, @"Collection view should not be nil");
    XCTAssertNotNil(self.vc.formattedPhoneNumberLabel, @"Formatted Phone Number Label should not be nil");
    XCTAssertNotNil(self.vc.registrationStatusLabel, @"Registration Status Label should not be nil");
    XCTAssertNotNil(self.vc.callButton, @"Call Button should not be nil");
    XCTAssertNotNil(self.vc.backspaceButton, @"Backspace Button should not be nil");
    XCTAssertNotNil(self.vc.plusLongPressGestureRecognizer, @"Plus Long Press Gesture Recongizer should not be nil");
    XCTAssertNotNil(self.vc.clearLongPressGestureRecognizer, @"Clear Long Press Gesture Recongizer should not be nil");
}

#pragma mark - Registration Status Tests -

-(void)test_registrationStatus_connected
{
    //TODO
}

-(void)test_registrationStatus_connecting
{
    //TODO
}

-(void)test_registrationStatus_wifiOnly_cellularData
{
    //TODO
}

-(void)test_registrationStatus_wifiOnly_disconnected
{
    //TODO
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
    
    NSInteger count = [self.vc collectionView:self.vc.collectionView numberOfItemsInSection:1];
    XCTAssertTrue(count == 14, @"incorrect count of the number of objects to be shown");
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
    Line *line = [Line MR_createInContext:self.context];
    OCMStub([self.vc.authenticationManager line]).andReturn(line);
    
    NSString *dialString = @"555555555";
    self.vc.formattedPhoneNumberLabel.dialString = dialString;
    
    // When
    [self.vc initiateCall:self.vc.callButton];
    
    OCMVerify([self.vc.phoneManager dialNumber:dialString usingLine:line type:JCPhoneManagerSingleDial completion:OCMOCK_ANY]);
}

-(void)test_dial_withoutPhoneNumber
{
    // Given
    Line *line = [Line MR_createInContext:self.context];
    OCMStub([self.vc.authenticationManager line]).andReturn(line);
    
    OutgoingCall *outgoingCall = [OutgoingCall MR_createInContext:self.context];
    outgoingCall.number = @"555555555";
    outgoingCall.line = line;
    outgoingCall.date = [NSDate date];
    
    __autoreleasing NSError *error;
    if(![outgoingCall.managedObjectContext save:&error]){
        XCTAssertNil(error, @"error saving outgoing call");
    }
    
    // We should not dial if there is no number.
    id phoneManagerMock = self.vc.phoneManager;
    [[[phoneManagerMock stub] andDo:^(NSInvocation *invocation) { XCTFail(@"Should not have called this method!"); }] dialNumber:OCMOCK_ANY usingLine:OCMOCK_ANY type:JCPhoneManagerSingleDial completion:OCMOCK_ANY];
    
    // When
    [self.vc initiateCall:self.vc.callButton];
    
    // Verify
    NSString *dialString = self.vc.formattedPhoneNumberLabel.dialString;
    XCTAssertTrue([outgoingCall.number isEqualToString:dialString], @"dial string do not match");
}

#pragma mark - Backspace Tests -

-(void)test_backspace_press
{
    
}

-(void)test_clear_press
{
    
}

@end
