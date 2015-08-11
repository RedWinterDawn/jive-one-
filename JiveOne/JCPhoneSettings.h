//
//  JCPhoneSettings.h
//  JiveOne
//
//  Created by Robert Barclay on 8/10/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

@import UIKit;

#import "JCSettings.h"

@class JCPhoneManager;

@interface JCPhoneSettings : JCSettings

@property (nonatomic, getter = isIntercomEnabled) BOOL intercomEnabled;
@property (nonatomic, getter = isIntercomMicrophoneMuteEnabled) BOOL intercomMicrophoneMuteEnabled;
@property (nonatomic, getter = isWifiOnly) BOOL wifiOnly;
@property (nonatomic, getter = isVibrateOnRing) BOOL vibrateOnRing;
@property (nonatomic, getter = isPhoneEnabled) BOOL phoneEnabled;
@property (nonatomic, getter = isDoNotDisturbEnabled) BOOL doNotDisturbEnabled;
@property (nonatomic) float volumeLevel;
@property (nonatomic) NSString *ringtone;

@end

@interface UIViewController (JCPhoneSettings)

// Utility function to abstract the process of toggling a setting from a control.
- (void)togglePhoneSettingForSender:(id)sender
                             action:(BOOL(^)(JCPhoneSettings *settings))action
                         completion:(void(^)(BOOL value, JCPhoneSettings *settings, JCPhoneManager *phoneManager))completion;

@end
