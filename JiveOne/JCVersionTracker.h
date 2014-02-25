//
//  JCVersionTracker.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 2/24/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^TrackerWithBlock)(void);

@interface JCVersionTracker : NSObject

@property (strong, nonatomic) NSDictionary          *versionHistory;
@property (assign, nonatomic) BOOL                  isFirstLaunch;
@property (assign, nonatomic) BOOL                  isFirstLaunchSinceUpdate;

+ (void)start;

+ (BOOL)isFirstLaunch;

+ (BOOL)isFirstLaunchSinceUpdate;

@end
