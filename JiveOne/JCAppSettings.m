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



NSString *const kJCAppSettingsPresenceAttribute = @"presenceEnabled";

NSString *const kJCAppSettingsAppSwitcherdLastSelectedIdentiferAttribute = @"applicationSwitcherLastSelected";
NSString *const kJCAppSettingsVoicemailOnSpeakerAttribute = @"voicemailOnSpeaker";


@implementation JCAppSettings

-(void)setPresenceEnabled:(BOOL)presenceEnabled
{
    [self setBoolValue:presenceEnabled forKey:kJCAppSettingsPresenceAttribute];
    [[NSNotificationCenter defaultCenter] postNotificationName:kJCAppSettingsPresenceChangedNotification object:self];
}

-(BOOL)isPresenceEnabled
{
    return [self.userDefaults boolForKey:kJCAppSettingsPresenceAttribute];
}

-(void)setVoicemailOnSpeaker:(BOOL)voicemailOnSpeaker
{
    [self setBoolValue:voicemailOnSpeaker forKey:kJCAppSettingsVoicemailOnSpeakerAttribute];
}

-(BOOL)isVoicemailOnSpeaker
{
    return [self.userDefaults boolForKey:kJCAppSettingsVoicemailOnSpeakerAttribute];
}

-(void)setAppSwitcherLastSelectedViewControllerIdentifier:(NSString *)lastSelectedViewControllerIdentifier
{
    [self setValue:lastSelectedViewControllerIdentifier forKey:kJCAppSettingsAppSwitcherdLastSelectedIdentiferAttribute];
}

-(NSString *)appSwitcherLastSelectedViewControllerIdentifier
{
    return [self.userDefaults valueForKey:kJCAppSettingsAppSwitcherdLastSelectedIdentiferAttribute];
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
