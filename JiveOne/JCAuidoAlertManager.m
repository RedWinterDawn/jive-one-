//
//  JCRingManager.m
//  JiveOne
//
//  Created by P Leonard on 1/21/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCAudioAlertManager.h"

@implementation JCAudioAlertManager


#pragma mark - Ringing

static bool incommingCall;

-(void)startVibration
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    bool vibrate = [userDefaults boolForKey:@"vibrateOnRing"];
    if (vibrate)
    {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
        AudioServicesAddSystemSoundCompletion(kSystemSoundID_Vibrate, NULL, NULL, endVibration, NULL);
    }
}


-(void)stopVibration
{
    incommingCall = false;
}

void endVibration (SystemSoundID ssID, void *clientData)
{
    if (!incommingCall)
        return;
    
    double delayInSeconds = 1;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if (!incommingCall)
            return;
        AudioServicesPlaySystemSound(ssID);
    });
}

-(void)startRingtone: (BOOL)Vibrate
{
    incommingCall = true;
    
    @try {
        if (Vibrate) {
            [self startVibration];
        }
        SystemSoundID soundId = [self playRingtone];
        AudioServicesAddSystemSoundCompletion(soundId, NULL, NULL, endRingtone, NULL);
    }
    @catch (NSException *exception) {
        NSLog(@"%@", exception.description);
    }
}

-(void)stopRingtone: (BOOL)Vibrate
{
    
    
    @try {
        if (Vibrate) {
            [self stopVibration];
        }
        incommingCall = false;
    }
    @catch (NSException *exception) {
        NSLog(@"%@", exception.description);
    }
}


void endRingtone (SystemSoundID ssID, void *clientData)
{
    if (!incommingCall)
        return;
    
    double delayInSeconds = 1;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if (!incommingCall)
            return;
        AudioServicesPlaySystemSound(ssID);
    });
}

-(SystemSoundID)playRingtone
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


-(void)stopRingtone
{
    incommingCall = false;
}




@end
