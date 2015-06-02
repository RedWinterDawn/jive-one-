//
//  JCAppSettings.m
//  JiveOne
//
//  Created by Robert Barclay on 12/8/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCAppSettings.h"
#import <objc/runtime.h>

NSString *const kJCAppSettingsIntercomEnabledAttribute = @"intercomEnabled";
NSString *const kJCAppSettingsIntercomMicrophoneMuteEnabledAttribute = @"intercomMicrophoneMuteEnabled";
NSString *const kJCAppSettingsWifiOnlyAttribute = @"wifiOnly";
NSString *const kJCAppSettingsPresenceAttribute = @"presenceEnabled";
NSString *const kJCAppSettingsVibrateOnRingAttribute = @"vibrateOnRing";
NSString *const kJCAppSettingsAppSwitcherdLastSelectedIdentiferAttribute = @"applicationSwitcherLastSelected";
NSString *const kJCAppSettingsVoicemailOnSpeakerAttribute = @"voicemailOnSpeaker";

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
}

-(void)setVibrateOnRing:(BOOL)vibrateOnRing
{
    [self setSettingBoolValue:vibrateOnRing forKey:kJCAppSettingsVibrateOnRingAttribute];
}

-(void)setVoicemailOnSpeaker:(BOOL)voicemailOnSpeaker
{
    [self setSettingBoolValue:voicemailOnSpeaker forKey:kJCAppSettingsVoicemailOnSpeakerAttribute];
}

-(void)setAppSwitcherLastSelectedViewControllerIdentifier:(NSString *)lastSelectedViewControllerIdentifier
{
    [self setSettingStringValue:lastSelectedViewControllerIdentifier forKey:kJCAppSettingsAppSwitcherdLastSelectedIdentiferAttribute];
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

-(NSString *)appSwitcherLastSelectedViewControllerIdentifier
{
    return [self.userDefaults valueForKey:kJCAppSettingsAppSwitcherdLastSelectedIdentiferAttribute];
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
    [self didChangeValueForKey:key];
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

@end
