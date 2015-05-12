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
        
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        [center addObserver:self selector:@selector(audioSessionRouteChangeSelector:) name:AVAudioSessionRouteChangeNotification object:audioSession];
        [center addObserver:self selector:@selector(audioSessionInteruptionSelector:) name:AVAudioSessionInterruptionNotification object:audioSession];
    }
    return self;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Setters -

-(void)setSpeaker:(BOOL)speaker
{
    __autoreleasing NSError *error;
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
    [session overrideOutputAudioPort:speaker ? AVAudioSessionPortOverrideSpeaker : AVAudioSessionPortOverrideNone error:&error];
    if (!error) {
        [session setActive:YES error:&error];
    }
}

#pragma mark - Getters -

-(BOOL)isPlaying {
    return _player.isPlaying;
}

-(BOOL)speaker
{
    AVAudioSessionRouteDescription *route = [AVAudioSession sharedInstance].currentRoute;
    for (AVAudioSessionPortDescription *port in route.outputs) {
        if ([port.portType isEqualToString:AVAudioSessionPortBuiltInSpeaker]) {
            return TRUE;
        }
    }
    return FALSE;
}

#pragma mark - Methods -

-(void)playPause {
    if (_player.isPlaying) {
        [self pause];
    }
    else {
        [self play];
    }
}

-(void)play {
    [_player play];
    _playbackTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(playbackRefresh) userInfo:nil repeats:YES];
    [_delegate didStartPlayback:self];
}

-(void)pause {
    [_player pause];
    [_delegate didPausePlayback:self];
    [_playbackTimer invalidate];
    _playbackTimer = nil;
}

-(void)stop {
    if (_player.isPlaying) {
        [_player stop];
    }
    [_playbackTimer invalidate];
    _playbackTimer = nil;
}

-(void)voiceMailAudioAvailable:(BOOL)available  {
    if (_player && _player.isPlaying) {
        [_player stop];
    }
    if (_player) {
        _player.delegate = self;
        [_player prepareToPlay];
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

#pragma mark - Notification Handlers

-(void)audioSessionRouteChangeSelector:(NSNotification *)notification
{
    [_delegate voicemailAudioPlayer:self didChangeToSpeaker:self.speaker];
}

-(void)audioSessionInteruptionSelector:(NSNotification *)notification
{
    [self pause];
}

@end
