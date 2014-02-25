//
//  JCVersionTracker.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 2/24/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCVersionTracker.h"

#define kJiveAppVersion @"keyjiveappversion"
#define kJiveAppFirstLaunch @"keyjiveappfirstlaunch"
#define kJiveAppVersionHistory @"keyjiveappversionhistory"
#define kJiveAppFirstLaunchSinceUpdate @"keyjiveappfirstlaunchsinceupdate"

#define _manager [JCVersionTracker sharedInstance]

@implementation JCVersionTracker

+(JCVersionTracker *)sharedInstance
{
    static JCVersionTracker *sharedObject = nil;
    @synchronized(self) {
        if (!sharedObject) {
            sharedObject = [[JCVersionTracker alloc] init];
        }
        return sharedObject;
    }
}

+ (void)start
{
    BOOL willSync = NO;
    
    NSDictionary *history = [[NSUserDefaults standardUserDefaults] objectForKey:kJiveAppVersionHistory];
    
    // if there's no history then it's first launch
    if (!history) {
        _manager.isFirstLaunch = YES;
        _manager.versionHistory = @{kJiveAppVersion : [NSMutableArray array]};
    }
    else {
        _manager.isFirstLaunch = NO;
        _manager.versionHistory = @{kJiveAppVersion: [history[kJiveAppVersion] mutableCopy]};
    }
    
    // check if update has been launched before
    if ([_manager.versionHistory[kJiveAppVersion] containsObject:[self currentVersion]]) {
        _manager.isFirstLaunchSinceUpdate = NO;
    }
    else {
        _manager.isFirstLaunchSinceUpdate = YES;
        [_manager.versionHistory[kJiveAppVersion] addObject:[self currentVersion]];
        willSync = YES;
    }
    
    // sync NSUserDefaults
    if (willSync) {
        [[NSUserDefaults standardUserDefaults] setObject:_manager.versionHistory forKey:kJiveAppVersionHistory];
    }
}

+ (BOOL)isFirstLaunch
{
    return _manager.isFirstLaunch;
}

+ (BOOL)isFirstLaunchSinceUpdate
{
    return _manager.isFirstLaunchSinceUpdate;
}

#pragma mark - Version

+ (NSString *)currentVersion
{
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
}

+ (NSArray *)versionHistory
{
    return _manager.versionHistory[kJiveAppVersion];
}

@end
