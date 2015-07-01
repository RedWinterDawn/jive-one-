//
//  JCAppSettings.h
//  JiveOne
//
//  Created by Robert Barclay on 12/8/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const kJCAppSettingsPresenceAttribute;

@interface JCAppSettings : NSObject

@property (nonatomic, getter = isIntercomEnabled) BOOL intercomEnabled;
@property (nonatomic, getter = isIntercomMicrophoneMuteEnabled) BOOL intercomMicrophoneMuteEnabled;
@property (nonatomic, getter = isWifiOnly) BOOL wifiOnly;
@property (nonatomic, getter = isPresenceEnabled) BOOL presenceEnabled;
@property (nonatomic, getter = isVibrateOnRing) BOOL vibrateOnRing;
@property (nonatomic, getter = isVoicemailOnSpeaker) BOOL voicemailOnSpeaker;
@property (nonatomic) float volumeLevel;

// Remembers the last selected view controller for the app switcher.
@property (nonatomic) NSString *appSwitcherLastSelectedViewControllerIdentifier;

@end

@interface JCAppSettings (Singleton)

+(instancetype)sharedSettings;

@end

@interface UIViewController (AppSettings)

@property(nonatomic, strong) JCAppSettings *appSettings;

@end