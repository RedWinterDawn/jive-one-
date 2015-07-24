//
//  JCAppSettings.h
//  JiveOne
//
//  Created by Robert Barclay on 12/8/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const kJCAppSettingsPresenceChangedNotification;

@interface JCAppSettings : NSObject

@property (nonatomic, getter = isIntercomEnabled) BOOL intercomEnabled;
@property (nonatomic, getter = isIntercomMicrophoneMuteEnabled) BOOL intercomMicrophoneMuteEnabled;
@property (nonatomic, getter = isWifiOnly) BOOL wifiOnly;
@property (nonatomic, getter = isPresenceEnabled) BOOL presenceEnabled;
@property (nonatomic, getter = isVibrateOnRing) BOOL vibrateOnRing;
@property (nonatomic, getter = isVoicemailOnSpeaker) BOOL voicemailOnSpeaker;
@property (nonatomic, getter = isSipDisabled) BOOL sipDisabled;
@property (nonatomic, getter= isDoNotDisturbEnabled) BOOL doNotDisturbEnabled;
@property (nonatomic) float volumeLevel;


// Remembers the last selected view controller for the app switcher.
@property (nonatomic) NSString *appSwitcherLastSelectedViewControllerIdentifier;

@property (nonatomic) NSString *ringtone;

@end

@interface JCAppSettings (Singleton)

+(instancetype)sharedSettings;

@end

@interface UIViewController (AppSettings)

@property(nonatomic, strong) JCAppSettings *appSettings;

// Utility function to abstract the process of toggling a setting from a control.
- (void)toggleSettingForSender:(id)sender
                        action:(BOOL(^)(JCAppSettings *settings))action
                    completion:(void(^)(BOOL value, JCAppSettings *settings))completion;

@end