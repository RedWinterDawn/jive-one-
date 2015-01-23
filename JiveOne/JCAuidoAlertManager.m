//
//  JCRingManager.m
//  JiveOne
//
//  Created by P Leonard on 1/21/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCAudioAlertManager.h"
#import "JCAppSettings.h"

#define DEFAULT_TIME_INTERVAL 1

@implementation JCAudioAlertManager

#pragma mark - Ringing

static BOOL active;

+(void)vibrate
{
    [self startRepeatingVibration:NO];
}

+(void)startRepeatingVibration:(BOOL)repeating
{
    active = repeating;
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    AudioServicesAddSystemSoundCompletion(kSystemSoundID_Vibrate, NULL, NULL, vibration, NULL);
}

+(void)stop
{
    active = false;
}

+(void)ring
{
    [self startRepeatingRingtone:NO];
}

+(void)startRepeatingRingtone:(BOOL)repeating
{
    active = repeating;
    @try {
        if ([JCAppSettings sharedSettings].isVibrateOnRing) {
            [self startRepeatingVibration:repeating];
        }
        SystemSoundID soundId = [self playRingtone];
        AudioServicesAddSystemSoundCompletion(soundId, NULL, NULL, ringtone, NULL);
    }
    @catch (NSException *exception) {
        NSLog(@"%@", exception.description);
    }
}

#pragma mark - Private -

void vibration (SystemSoundID ssID, void *clientData)
{
    if (!active)
        return;
    
    double delayInSeconds = DEFAULT_TIME_INTERVAL;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if (!active)
            return;
        AudioServicesPlaySystemSound(ssID);
    });
}

void ringtone (SystemSoundID ssID, void *clientData)
{
    if (!active)
        return;
    
    double delayInSeconds = DEFAULT_TIME_INTERVAL;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if (!active)
            return;
        AudioServicesPlaySystemSound(ssID);
    });
}

+ (SystemSoundID)playRingtone
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSURL *url = [NSURL fileURLWithPath:@"/System/Library/Audio/UISounds/vc~ringing.caf"];
    SystemSoundID soundID;
    AudioServicesCreateSystemSoundID((__bridge_retained CFURLRef)url, &soundID);
    AudioServicesPlaySystemSound(soundID);
    
    bool vibrate = [userDefaults boolForKey:@"vibrateOnRing"];
    if (vibrate)
        AudioServicesPlaySystemSound(4095);
    return soundID;
}




@end
