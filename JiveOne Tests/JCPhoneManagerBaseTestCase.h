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

#import "JCBaseUITestCase.h"

@interface JCPhoneManager (Private)

@property (nonatomic, strong) UIStoryboard *storyboard;

-(void)dialNumber:(NSString *)dialString usingLine:(Line *)line type:(JCPhoneManagerDialType)dialType completion:(CompletionHandler)completion;

@end

@interface JCPhoneManagerBaseTestCase : JCBaseUITestCase

@property (nonatomic, strong) JCPhoneManager *phoneManager;

@end
