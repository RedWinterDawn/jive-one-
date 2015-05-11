//
//  JCVoicemailAudioPlayer.m
//  JiveOne
//
//  Created by P Leonard on 5/11/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCVoicemailAudioPlayer.h"

@interface JCVoicemailAudioPlayer () <AVAudioPlayerDelegate>
{
    AVAudioPlayer *player;
    NSData *soundData;
    BOOL _playThroughSpeaker;
}


@end

@implementation JCVoicemailAudioPlayer

-(BOOL)isPlaying {
    return [player isPlaying];
}
-(void)voiceMailAudioAvailable:(BOOL)available  {
    if(player && player.isPlaying)  {
        [player stop];
    }
    NSError *error;
    player = [[AVAudioPlayer alloc] initWithData:self.voicemail fileTypeHint:AVFileTypeWAVE error:&error];
    if (player) {
        [self setupSpeaker];
        player.delegate = self;
        [player prepareToPlay];
//        [self updateViewForPlayerInfo];
    }
}

-(void)playPauseAudio {
    BOOL playing = player.isPlaying;
    
    if (playing) {
        //Pause
        [player pause];
        
//        [self stopProgressTimerForVoicemail];
//        self.playPauseButton.selected = FALSE;
        [UIDevice currentDevice].proximityMonitoringEnabled = NO;
    }
    else {
        //Play
        [player play];
//        [self startProgressTimerForVoicemail];
//        self.playPauseButton.selected = TRUE;
//        [self.voicemail markAsRead:NULL];
        [UIDevice currentDevice].proximityMonitoringEnabled = YES;
    }
}

-(void)setSliderValue:(float *)position{
    
    return;
//    todo: return where we are in the voicemail
}

-(BOOL)getIsPlaying {
    return [player isPlaying];
}




- (void)setupSpeaker
{
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError *error;
    
    // set category PlanAndRecord in order to be able to use AudioRoueOverride
    [session setCategory:AVAudioSessionCategoryPlayAndRecord
                   error:&error];
    
    AVAudioSessionPortOverride portOverride = _playThroughSpeaker ? AVAudioSessionPortOverrideSpeaker : AVAudioSessionPortOverrideNone;
    [session overrideOutputAudioPort:portOverride error:&error];
    
    if (!error) {
        [session setActive:YES error:&error];
        
//        if (!error) {
//            if (_playThroughSpeaker) {
//                self.speakerButton.selected = YES;
//            }
//            else {
//                self.speakerButton.selected = NO;
//            }
//        }
    }
}
@end
