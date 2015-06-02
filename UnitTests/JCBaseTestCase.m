//
//  JCCoreDataBaseTestCase.m
//  JiveOne
//
//  Created by Robert Barclay on 3/27/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCBaseTestCase.h"
#import "JCCoreDataTestDataFactory.h"

@implementation JCBaseTestCase

- (void)setUp {
    [super setUp];
    
    [MagicalRecord cleanUp];
    [MagicalRecord setDefaultModelFromClass:[self class]];
    [MagicalRecord setupCoreDataStackWithInMemoryStore];
    _context = [NSManagedObjectContext MR_defaultContext];
    
    [JCCoreDataTestDataFactory loadTestCoreDataTestDataOnContext:_context];
}

- (void)tearDown {
    
    [MagicalRecord cleanUp];
    [super tearDown];
}

@end
