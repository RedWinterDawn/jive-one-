//
//  JCTransferViewControllerTests.m
//  JiveOne
//
//  Created by Robert Barclay on 3/31/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCPhoneManagerBaseTestCase.h"
#import "JCTransferViewController.h"

@interface JCTransferViewControllerTests : JCPhoneManagerBaseTestCase

@property (nonatomic, strong) JCTransferViewController *vc;

@end

@implementation JCTransferViewControllerTests

- (void)setUp {
    [super setUp];
    
    self.vc = [self.storyboard instantiateViewControllerWithIdentifier:@"warmTransferModal"];
    [self.vc performSelectorOnMainThread:@selector(loadView) withObject:nil waitUntilDone:YES];
}

- (void)tearDown {
    self.vc = nil;
    [super tearDown];
}

- (void)testExample {
    XCTAssertNotNil(self.vc, @"View not initiated properly");
    XCTAssertTrue([self.vc isKindOfClass:[JCTransferViewController class]], @"View controller should be kind of class: %@", [JCTransferViewController class]);
    XCTAssertNotNil(self.vc.view, @"View should not be nil");
    XCTAssertNotNil(self.vc.collectionView, @"Collection view should not be nil");
    XCTAssertNotNil(self.vc.formattedPhoneNumberLabel, @"Formatted Phone Number Label should not be nil");
    XCTAssertNotNil(self.vc.callButton, @"Call Button should not be nil");
    XCTAssertNotNil(self.vc.backspaceButton, @"Backspace Button should not be nil");
}

@end
