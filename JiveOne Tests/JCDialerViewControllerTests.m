//
//  JCDialerViewControllerTests.m
//  JiveOne
//
//  Created by Robert Barclay on 3/31/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCMainStoryboardBaseTestCase.h"
#import "JCDialerViewController.h"

@interface JCDialerViewControllerTests : JCMainStoryboardBaseTestCase

@property (nonatomic, strong) JCDialerViewController *vc;

@end

@implementation JCDialerViewControllerTests

- (void)setUp {
    [super setUp];
    self.vc = [self.storyboard instantiateViewControllerWithIdentifier:@"JCDialerViewController"];
    [self.vc performSelectorOnMainThread:@selector(loadView) withObject:nil waitUntilDone:YES];
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

@end
