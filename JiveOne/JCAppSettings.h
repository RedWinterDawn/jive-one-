//
//  JCAppSettings.h
//  JiveOne
//
//  Created by Robert Barclay on 12/8/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCSettings.h"

extern NSString *const kJCAppSettingsPresenceChangedNotification;

@interface JCAppSettings : JCSettings

@property (nonatomic, getter = isPresenceEnabled) BOOL presenceEnabled;
@property (nonatomic, getter = isVoicemailOnSpeaker) BOOL voicemailOnSpeaker;

// Remembers the last selected view controller for the app switcher.
@property (nonatomic) NSString *appSwitcherLastSelectedViewControllerIdentifier;

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