//
//  JCLoginTestCase.m
//  JiveOne
//
//  Created by Daniel George on 6/23/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <KIF/KIF.h>
#import "KIFUITestActor+Additions.h"

@interface ITLoginTestCase : KIFTestCase

@end

@implementation ITLoginTestCase

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample
{
    XCTAssert(1==1, @"No implementation for \"%s\"", __PRETTY_FUNCTION__);
}

@end
