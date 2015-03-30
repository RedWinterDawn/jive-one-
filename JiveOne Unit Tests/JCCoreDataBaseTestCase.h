//
//  JCCoreDataBaseTestCase.h
//  JiveOne
//
//  Created by Robert Barclay on 3/27/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <MagicalRecord/MagicalRecord.h>

@interface JCCoreDataBaseTestCase : XCTestCase

@property (nonatomic, readonly) NSManagedObjectContext *context;

@end
