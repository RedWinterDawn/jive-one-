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

static AVAudioPlayer *ringbackAudioPlayer;
static SystemSoundID ringtoneID;

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
    
    if (ringtoneID) {
        AudioServicesRemoveSystemSoundCompletion (ringtoneID);
        AudioServicesDisposeSystemSoundID(ringtoneID);
        ringtoneID = false;
    }
    
    __autoreleasing NSError *error;
    if (![[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:&error]) {
        NSLog(@"%@", error);
    }
    
    if (ringbackAudioPlayer) {
        [ringbackAudioPlayer stop];
        ringbackAudioPlayer = nil;
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
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        NSArray *outputs = audioSession.currentRoute.outputs;
        AVAudioSessionPortDescription *port = [outputs lastObject];
        if ([port.portType isEqualToString:AVAudioSessionPortBuiltInReceiver]) {
            __autoreleasing NSError *error;
            if (![audioSession overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&error]) {
                NSLog(@"%@", error);
            }
        }
        
        AudioServicesCreateSystemSoundID((__bridge_retained CFURLRef)url, &ringtoneID);
        AudioServicesPlaySystemSound(ringtoneID);
        CFBridgingRelease((__bridge CFURLRef)url);
        
        AudioServicesAddSystemSoundCompletion(ringtoneID, NULL, NULL, ringtone, NULL);
        
        if ([JCAppSettings sharedSettings].isVibrateOnRing)
            [self startRepeatingVibration:repeating];
    }
    @catch (NSException *exception) {
        NSLog(@"%@", exception.description);
    }
}

+ (void)startRingback
{
    if (!ringbackAudioPlayer) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"calling" ofType:@"mp3"];
        NSURL *url = [NSURL fileURLWithPath:path];
        __autoreleasing NSError *error;
        ringbackAudioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
        [ringbackAudioPlayer prepareToPlay];
    }
    
    if (!ringbackAudioPlayer.isPlaying) {
        [ringbackAudioPlayer play];
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
