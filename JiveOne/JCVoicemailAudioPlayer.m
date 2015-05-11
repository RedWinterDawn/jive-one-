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
    NSData *soundData;
    BOOL _playThroughSpeaker;
    
    AVAudioPlayer *_player;
    NSTimer *_playbackTimer;
}


@end

@implementation JCVoicemailAudioPlayer

-(instancetype)initWithVoicemail:(Voicemail *)voicemail
{
    self = [super init];
    if (self) {
        __autoreleasing NSError *error;
        _player = [[AVAudioPlayer alloc] initWithData:voicemail.data fileTypeHint:AVFileTypeWAVE error:&error];
        _player.delegate = self;
        [_player prepareToPlay];
    }
    return self;
}

-(BOOL)isPlaying {
    return _player.isPlaying;
}
-(void)voiceMailAudioAvailable:(BOOL)available  {
    if (_player && _player.isPlaying) {
        [_player stop];
    }
    if (_player) {
        [self setupSpeaker];
        _player.delegate = self;
        [_player prepareToPlay];
    }
}

-(void)playPause {
    if (_player.isPlaying) {
        [_playbackTimer invalidate];
        _playbackTimer = nil;
        [_player pause];
        [_delegate didPausePlayback:self];
    }
    else {
        [_player play];
        _playbackTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(playbackRefresh) userInfo:nil repeats:YES];
        [_delegate didStartPlayback:self];
    }
}

-(void)playbackRefresh
{
    // TODO: Tell delegate that we have updated our playback position, and it should update any UI based on that position.
}

-(void)setSliderValue:(float)position{
    NSTimeInterval startTime =  (MIN(position, 1.0f) * _player.duration);
    [_player playAtTime: startTime];
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
        
    }
}
@end
