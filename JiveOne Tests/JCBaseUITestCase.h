//
//  JCBaseUITestCase.h
//  JiveOne
//
//  Created by Robert Barclay on 4/1/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <CoreData/CoreData.h>

@interface JCBaseUITestCase : XCTestCase

@property (nonatomic, readonly) NSManagedObjectContext *context;

@end