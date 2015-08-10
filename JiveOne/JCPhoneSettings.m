//
//  JCPhoneSettings.m
//  JiveOne
//
//  Created by Robert Barclay on 8/10/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCPhoneSettings.h"
#import "JCPhoneManager.h"

@implementation JCPhoneSettings

#pragma mark - Properties -

-(void)setPhoneEnabled:(BOOL)sipDisabled
{
    [self setBoolValue:sipDisabled forKey:NSStringFromSelector(@selector(isPhoneEnabled))];
}

-(BOOL)isPhoneEnabled
{
    return [self.userDefaults boolForKey:NSStringFromSelector(@selector(isPhoneEnabled))];
}

-(void)setDoNotDisturbEnabled:(BOOL)doNotDisturbEnabled
{
    [self setBoolValue:doNotDisturbEnabled forKey:NSStringFromSelector(@selector(isDoNotDisturbEnabled))];
}

-(BOOL)isDoNotDisturbEnabled
{
    return [self.userDefaults boolForKey:NSStringFromSelector(@selector(isDoNotDisturbEnabled))];
}

-(void)setIntercomEnabled:(BOOL)intercomEnabled
{
    [self setBoolValue:intercomEnabled forKey:NSStringFromSelector(@selector(isIntercomEnabled))];
}

-(BOOL)isIntercomEnabled
{
    return [self.userDefaults boolForKey:NSStringFromSelector(@selector(isIntercomEnabled))];
}

-(void)setIntercomMicrophoneMuteEnabled:(BOOL)intercomMicrophoneMuteEnabled
{
    [self setBoolValue:intercomMicrophoneMuteEnabled forKey:NSStringFromSelector(@selector(isIntercomMicrophoneMuteEnabled))];
}

-(BOOL)isIntercomMicrophoneMuteEnabled
{
    return [self.userDefaults boolForKey:NSStringFromSelector(@selector(isIntercomMicrophoneMuteEnabled))];
}

-(void)setWifiOnly:(BOOL)callsOverCellEnabled
{
    [self setBoolValue:callsOverCellEnabled forKey:NSStringFromSelector(@selector(isWifiOnly))];
}

-(BOOL)isWifiOnly
{
    return [self.userDefaults boolForKey:NSStringFromSelector(@selector(isWifiOnly))];
}

-(void)setVibrateOnRing:(BOOL)vibrateOnRing
{
    [self setBoolValue:vibrateOnRing forKey:NSStringFromSelector(@selector(isVibrateOnRing))];
}

-(BOOL)isVibrateOnRing
{
    return [self.userDefaults boolForKey:NSStringFromSelector(@selector(isVibrateOnRing))];
}

-(void)setRingtone:(NSString *)ringTone
{
    [self setValue:ringTone forKey:NSStringFromSelector(@selector(ringtone))];
}

-(NSString *)ringtone
{
    return [self.userDefaults valueForKey:NSStringFromSelector(@selector(ringtone))];
}

-(void)setVolumeLevel:(float )volumeLevel
{
    [self setFloatValue:volumeLevel forKey:NSStringFromSelector(@selector(volumeLevel))];
}

-(float)volumeLevel
{
    return [self.userDefaults floatForKey:NSStringFromSelector(@selector(volumeLevel))];
}

@end

@implementation UIViewController (JCPhoneSettings)

- (void)togglePhoneSettingForSender:(id)sender action:(BOOL(^)(JCPhoneSettings *settings))action completion:(void(^)(BOOL value, JCPhoneSettings *settings, JCPhoneManager *phoneManager))completion
{
    JCPhoneManager *phoneManager = self.phoneManager;
    JCPhoneSettings *settings = phoneManager.settings;
    if ([sender isKindOfClass:[UISwitch class]]){
        UISwitch *switchBtn = (UISwitch *)sender;
        BOOL result = action(settings);
        switchBtn.on = result;
        if (completion) {
            completion(result, settings, phoneManager);
        }
    } else {
        BOOL result = action(settings);
        if (completion) {
            completion(result, settings, phoneManager);
        }
    }
}

@end
