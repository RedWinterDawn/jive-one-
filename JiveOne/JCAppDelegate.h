//
//  JCAppDelegate.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 2/13/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UAirship.h"
#import "UAConfig.h"
#import "UAPush.h"

@interface JCAppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic, strong) UIWindow *window;
@property (nonatomic) BOOL seenTutorial;

- (void)changeRootViewController:(JCRootViewControllerType)type;
- (void)startSocket:(BOOL)inBackground;
- (void)stopSocket;
- (void)didLogInSoCanRegisterForPushNotifications;
- (void)didLogOutSoUnRegisterForPushNotifications;

- (void)stopRingtone;

- (void)cleanAndResetDatabase;

@end
