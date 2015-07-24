//
//  JCAppSettings.m
//  JiveOne
//
//  Created by Robert Barclay on 12/8/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCAppSettings.h"
#import <objc/runtime.h>

NSString *const kJCAppSettingsPresenceChangedNotification = @"presenceChanged";

NSString *const kJCAppSettingsIntercomEnabledAttribute = @"intercomEnabled";
NSString *const kJCAppSettingsIntercomMicrophoneMuteEnabledAttribute = @"intercomMicrophoneMuteEnabled";
NSString *const kJCAppSettingsWifiOnlyAttribute = @"wifiOnly";
NSString *const kJCAppSettingsPresenceAttribute = @"presenceEnabled";
NSString *const kJCAppSettingsVibrateOnRingAttribute = @"vibrateOnRing";
NSString *const kJCAppSettingsAppSwitcherdLastSelectedIdentiferAttribute = @"applicationSwitcherLastSelected";
NSString *const kJCAppSettingsVoicemailOnSpeakerAttribute = @"voicemailOnSpeaker";
NSString *const kJCAppSettingsPhoneEnabledAttribute = @"phoneEnabled";
NSString *const kJCAppSettingsVolumeLevelAttribute = @"volumeLevel";
NSString *const kJCRingToneSelectedAttribute = @"ringtone";
NSString *const kJCDoNotDisturbAttribute = @"DoNotDisturb";


@interface JCAppSettings ()

@property (nonatomic, strong) NSUserDefaults *userDefaults;

@end

@implementation JCAppSettings

-(instancetype)initWithDefaults:(NSUserDefaults *)userDefaults
{
    self = [super init];
    if (self) {
        _userDefaults = userDefaults;
    }
    return self;
}

-(instancetype)init
{
    return [self initWithDefaults:[NSUserDefaults standardUserDefaults]];
}

#pragma mark - Setters -

-(void)setIntercomEnabled:(BOOL)intercomEnabled
{
    [self setSettingBoolValue:intercomEnabled forKey:kJCAppSettingsIntercomEnabledAttribute];
}

-(void)setIntercomMicrophoneMuteEnabled:(BOOL)intercomMicrophoneMuteEnabled
{
    [self setSettingBoolValue:intercomMicrophoneMuteEnabled forKey:kJCAppSettingsIntercomMicrophoneMuteEnabledAttribute];
}

-(void)setWifiOnly:(BOOL)callsOverCellEnabled
{
    [self setSettingBoolValue:callsOverCellEnabled forKey:kJCAppSettingsWifiOnlyAttribute];
}

-(void)setPresenceEnabled:(BOOL)presenceEnabled
{
    [self setSettingBoolValue:presenceEnabled forKey:kJCAppSettingsPresenceAttribute];
    [[NSNotificationCenter defaultCenter] postNotificationName:kJCAppSettingsPresenceChangedNotification object:self];
}

-(void)setVibrateOnRing:(BOOL)vibrateOnRing
{
    [self setSettingBoolValue:vibrateOnRing forKey:kJCAppSettingsVibrateOnRingAttribute];
}

-(void)setVoicemailOnSpeaker:(BOOL)voicemailOnSpeaker
{
    [self setSettingBoolValue:voicemailOnSpeaker forKey:kJCAppSettingsVoicemailOnSpeakerAttribute];
}

-(void)setPhoneEnabled:(BOOL)sipDisabled
{
    [self setSettingBoolValue:sipDisabled forKey:kJCAppSettingsPhoneEnabledAttribute];
}

-(void)setDoNotDisturbEnabled:(BOOL)doNotDisturbEnabled
{
    [self setSettingBoolValue:doNotDisturbEnabled forKey:kJCDoNotDisturbAttribute];
}

-(void)setAppSwitcherLastSelectedViewControllerIdentifier:(NSString *)lastSelectedViewControllerIdentifier
{
    [self setSettingStringValue:lastSelectedViewControllerIdentifier forKey:kJCAppSettingsAppSwitcherdLastSelectedIdentiferAttribute];
}

-(void)setRingtone:(NSString *)ringTone
{
    [self setSettingStringValue:ringTone forKey:kJCRingToneSelectedAttribute];
}

-(void)setVolumeLevel:(float )volumeLevel
{
    [self setFloatValue:volumeLevel forKey:kJCAppSettingsVolumeLevelAttribute];
}


#pragma mark - Getters -

-(BOOL)isIntercomEnabled
{
    return [self.userDefaults boolForKey:kJCAppSettingsIntercomEnabledAttribute];
}
-(BOOL)isIntercomMicrophoneMuteEnabled
{
    return [self.userDefaults boolForKey:kJCAppSettingsIntercomMicrophoneMuteEnabledAttribute];
}
-(BOOL)isWifiOnly
{
    return [self.userDefaults boolForKey:kJCAppSettingsWifiOnlyAttribute];
}

-(BOOL)isPresenceEnabled
{
    return [self.userDefaults boolForKey:kJCAppSettingsPresenceAttribute];
}

-(BOOL)isVibrateOnRing
{
    return [self.userDefaults boolForKey:kJCAppSettingsVibrateOnRingAttribute];
}

-(BOOL)isVoicemailOnSpeaker
{
    return [self.userDefaults boolForKey:kJCAppSettingsVoicemailOnSpeakerAttribute];
}

-(BOOL)isPhoneEnabled
{
    return [self.userDefaults boolForKey:kJCAppSettingsPhoneEnabledAttribute];
}

-(BOOL)isDoNotDisturbEnabled
{
    return [self.userDefaults boolForKey:kJCDoNotDisturbAttribute];
}

-(NSString *)appSwitcherLastSelectedViewControllerIdentifier
{
    return [self.userDefaults valueForKey:kJCAppSettingsAppSwitcherdLastSelectedIdentiferAttribute];
}

-(NSString *)ringtone
{
    return [self.userDefaults valueForKey:kJCRingToneSelectedAttribute];
}

-(float)volumeLevel
{
    return [self.userDefaults floatForKey:kJCAppSettingsVolumeLevelAttribute];
}


#pragma mark - Private -

-(void)setSettingBoolValue:(BOOL)value forKey:(NSString *)key
{
    [self willChangeValueForKey:key];
    NSUserDefaults *defaults = self.userDefaults;
    [defaults setBool:value forKey:key];
    [defaults synchronize];
    [self didChangeValueForKey:key];
}

-(void)setSettingStringValue:(NSString *)value forKey:(NSString *)key
{
    [self willChangeValueForKey:key];
    NSUserDefaults *defaults = self.userDefaults;
    [defaults setValue:value forKey:key];
    [defaults synchronize];
    [self didChangeValueForKey:key];
}

-(void)setFloatValue:(float)value forKey:(NSString *)key
{
    [self willChangeValueForKey:key];
    NSUserDefaults *defaults = self.userDefaults;
    [defaults setFloat:value forKey:key];
    [defaults synchronize];
}

@end

@implementation JCAppSettings (Singleton)

+(instancetype)sharedSettings
{
    static JCAppSettings *singleton = nil;
    static dispatch_once_t pred;        // Lock
    dispatch_once(&pred, ^{             // This code is called at most once per app
        singleton = [[JCAppSettings alloc] init];
    });
    return singleton;
}

+ (id)copyWithZone:(NSZone *)zone
{
    return self;
}

@end

@implementation UIViewController (AppSettings)

- (void)setAppSettings:(JCAppSettings *)appSettings {
    objc_setAssociatedObject(self, @selector(appSettings), appSettings, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(JCAppSettings *)appSettings
{
    JCAppSettings *appSettings = objc_getAssociatedObject(self, @selector(appSettings));
    if (!appSettings)
    {
        appSettings = [JCAppSettings sharedSettings];
        objc_setAssociatedObject(self, @selector(appSettings), appSettings, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return appSettings;
}

- (void)toggleSettingForSender:(id)sender action:(BOOL(^)(JCAppSettings *settings))action completion:(void(^)(BOOL value, JCAppSettings *settings))completion
{
    JCAppSettings *setting = self.appSettings;
    if ([sender isKindOfClass:[UISwitch class]]){
        UISwitch *switchBtn = (UISwitch *)sender;
        BOOL result = action(setting);
        switchBtn.on = result;
        if (completion) {
            completion(result, setting);
        }
    } else {
        BOOL result = action(setting);
        if (completion) {
            completion(result, setting);
        }
    }
}


@end
