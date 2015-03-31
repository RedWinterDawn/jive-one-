//
//  JCPhoneManagerBaseTestCase.m
//  JiveOne
//
//  Created by Robert Barclay on 3/31/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCPhoneManagerBaseTestCase.h"

@implementation JCPhoneManagerBaseTestCase

- (void)setUp {
    [super setUp];
    self.storyboard = [UIStoryboard storyboardWithName:@"PhoneManager" bundle:[NSBundle mainBundle]];
}

- (void)tearDown {
    self.storyboard = nil;
    [super tearDown];
}

- (void)test_phone_manager_storyboard
{
    XCTAssertNotNil(self.storyboard, @"Storyboard should not be nil");
}

@end
