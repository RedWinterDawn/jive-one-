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

@implementation JCAppSettings

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

#pragma mark - Getters -

-(BOOL)isIntercomEnabled
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:kJCAppSettingsIntercomEnabledAttribute];
}
-(BOOL)isIntercomMicrophoneMuteEnabled
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:kJCAppSettingsIntercomMicrophoneMuteEnabledAttribute];
}
-(BOOL)isWifiOnly
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:kJCAppSettingsWifiOnlyAttribute];
}

-(BOOL)isPresenceEnabled
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:kJCAppSettingsPresenceAttribute];
}

-(BOOL)isVibrateOnRing
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:kJCAppSettingsVibrateOnRingAttribute];
}

#pragma mark - Private -

-(void)setSettingBoolValue:(BOOL)value forKey:(NSString *)key
{
    [self willChangeValueForKey:key];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:value forKey:key];
    [defaults synchronize];
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
