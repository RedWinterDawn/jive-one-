//
//  JCPhoneManagerBaseTestCase.h
//  JiveOne
//
//  Created by Robert Barclay on 3/31/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "JCPhoneManager.h"

@interface JCPhoneManager (Private)

@property (nonatomic, strong) JCSipManager *sipManager;
@property (nonatomic, strong) UIStoryboard *storyboard;

@end

@interface JCPhoneManagerBaseTestCase : XCTestCase

@property (nonatomic, strong) JCPhoneManager *phoneManager;

@end
