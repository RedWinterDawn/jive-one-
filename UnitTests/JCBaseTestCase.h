//
//  JCCoreDataBaseTestCase.h
//  JiveOne
//
//  Created by Robert Barclay on 3/27/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

@import Foundation;
@import UIKit;
@import XCTest;
@import CoreData;

#import <OCMock/OCMock.h>
#import <MagicalRecord/MagicalRecord.h>
#import <AFNetworking/AFNetworkReachabilityManager.h>
#import <UIKit/UIGestureRecognizerSubclass.h>

@interface JCBaseTestCase : XCTestCase

@property (nonatomic, readonly) NSManagedObjectContext *context;

@end
