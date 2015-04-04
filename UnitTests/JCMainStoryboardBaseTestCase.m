//
//  JCViewControllerMainBaseTestCase.m
//  JiveOne
//
//  Created by Robert Barclay on 3/31/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCMainStoryboardBaseTestCase.h"

@implementation JCMainStoryboardBaseTestCase

- (void)setUp {
    [super setUp];
    self.storyboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle:[NSBundle mainBundle]];
}

- (void)tearDown {
    self.storyboard = nil;
    [super tearDown];
}

- (void)test_main_storyboard
{
    XCTAssertNotNil(self.storyboard, @"Storyboard should not be nil");
}

@end
