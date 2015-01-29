//
//  JCRingManager.m
//  JiveOne
//
//  Created by P Leonard on 1/21/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCAudioAlertManager.h"
#import "JCAppSettings.h"

@import AVFoundation;

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
    
    __autoreleasing NSError *error;
    if (![[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:&error]) {
        NSLog(@"%@", error);
    }
}

+(void)ring
{
    [self startRepeatingRingtone:NO];
}

+(void)startRepeatingRingtone:(BOOL)repeating
{
    active = repeating;
    @try {
        NSURL *url = [NSURL fileURLWithPath:@"/System/Library/Audio/UISounds/vc~ringing.caf"];
        SystemSoundID soundID;
        
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        NSArray *outputs = audioSession.currentRoute.outputs;
        AVAudioSessionPortDescription *port = [outputs lastObject];
        if ([port.portType isEqualToString:AVAudioSessionPortBuiltInReceiver]) {
            __autoreleasing NSError *error;
            if (![audioSession overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&error]) {
                NSLog(@"%@", error);
            }
        }
        
        AudioServicesCreateSystemSoundID((__bridge_retained CFURLRef)url, &soundID);
        AudioServicesPlaySystemSound(soundID);
        CFBridgingRelease((__bridge CFURLRef)url);
        
        AudioServicesAddSystemSoundCompletion(soundID, NULL, NULL, ringtone, NULL);
        
        if ([JCAppSettings sharedSettings].isVibrateOnRing)
            [self startRepeatingVibration:repeating];
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




@end
