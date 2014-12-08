//
//  JCAppSettings.m
//  JiveOne
//
//  Created by Robert Barclay on 12/8/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCAppSettings.h"

NSString *const kJCAppSettingsIntercomeEnabledAttribute = @"intercomEnabled";

@implementation JCAppSettings

#pragma mark - Setters -

-(void)setIntercomEnabled:(BOOL)intercomEnabled
{
    [self setSettingBoolValue:intercomEnabled forKey:kJCAppSettingsIntercomeEnabledAttribute];
}

#pragma mark - Getters -

-(BOOL)isIntercomEnabled
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:kJCAppSettingsIntercomeEnabledAttribute];
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