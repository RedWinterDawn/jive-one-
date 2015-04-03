//
//  JCBaseUITestCase.m
//  JiveOne
//
//  Created by Robert Barclay on 4/1/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCBaseUITestCase.h"
#import <MagicalRecord/MagicalRecord+Setup.h>
#import <MagicalRecord/NSManagedObjectContext+MagicalRecord.h>

@implementation JCBaseUITestCase

- (void)setUp {
    [super setUp];
    
    [MagicalRecord setDefaultModelFromClass:[self class]];
    [MagicalRecord setupCoreDataStackWithInMemoryStore];
    _context = [NSManagedObjectContext MR_defaultContext];
}

- (void)tearDown {
    
    [MagicalRecord cleanUp];
    
    [super tearDown];
}

@end
