//
//  JCApplicationSwitcherDataSource.h
//  JCApplicationSwitcher
//
//  Created by Robert Barclay on 10/17/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JCApplicationSwitcherViewController.h"

extern NSString *const kApplicationSwitcherPhoneRestorationIdentifier;

@interface JCApplicationSwitcherDelegate : NSObject <JCApplicationSwitcherDelegate>

+(void)reset;

@end
