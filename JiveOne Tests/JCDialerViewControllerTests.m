//
//  JCDialerViewControllerTests.m
//  JiveOne
//
//  Created by Robert Barclay on 3/31/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCMainStoryboardBaseTestCase.h"
#import "JCDialerViewController.h"
#import "JCPhoneManager.h"
#import "JCFormattedPhoneNumberLabel.h"
#import "JCAuthenticationManager.h"
#import "Line.h"
#import "OutgoingCall.h"
#import <MagicalRecord/NSManagedObject+MagicalRecord.h>
#import <MagicalRecord+Actions.h>

@interface JCPhoneManager ()

-(void)dialNumber:(NSString *)dialString usingLine:(Line *)line type:(JCPhoneManagerDialType)dialType completion:(CompletionHandler)completion;

@end

@interface JCDialerViewController (Private)

@property (nonatomic, strong) JCAuthenticationManager *authenticationManager;
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

-(void)test_JCDialerViewController_storyboard_initialization
{
    XCTAssertNotNil(self.vc, @"View not initiated properly");
    XCTAssertTrue([self.vc isKindOfClass:[JCDialerViewController class]], @"View controller should be kind of class: %@", [JCDialerViewController class]);
    XCTAssertNotNil(self.vc.view, @"View should not be nil");
    XCTAssertNotNil(self.vc.collectionView, @"Collection view should not be nil");
    XCTAssertNotNil(self.vc.formattedPhoneNumberLabel, @"Formatted Phone Number Label should not be nil");
    XCTAssertNotNil(self.vc.registrationStatusLabel, @"Registration Status Label should not be nil");
    XCTAssertNotNil(self.vc.callButton, @"Call Button should not be nil");
    XCTAssertNotNil(self.vc.backspaceButton, @"Backspace Button should not be nil");
}

-(void)test_JCDialerViewController_dial_withPhoneNumber
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

-(void)test_JCDialerViewController_dial_withoutPhoneNumber
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

@end
