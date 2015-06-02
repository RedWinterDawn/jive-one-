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
    id <JCVoicemailAudioPlayerDelegate> _delegate;
}

@end

@implementation JCVoicemailAudioPlayer

-(instancetype)initWithVoicemail:(Voicemail *)voicemail delegate:(id<JCVoicemailAudioPlayerDelegate>)delegate
{
    self = [super init];
    if (self) {
        _delegate = delegate;
        
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
        [audioSession setActive:YES error:nil];
        
        __autoreleasing NSError *error;
        _player = [[AVAudioPlayer alloc] initWithData:voicemail.data fileTypeHint:AVFileTypeWAVE error:&error];
        
        if (error) {
            [_delegate voicemailAudioPlayer:self didFailWithError:error];
        }
        
        _player.delegate = self;
        BOOL result = [_player prepareToPlay];
        if (result) {
            [_delegate voicemailAudioPlayer:self didLoadWithDuration:_player.duration];
        }
        
        // Notifiy of the initial speaker state
        [_delegate voicemailAudioPlayer:self didChangeToSpeaker:self.speaker];
        
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(audioSessionRouteChangeSelector:) name:AVAudioSessionRouteChangeNotification object:nil];
        [center addObserver:self selector:@selector(audioSessionInteruptionSelector:) name:AVAudioSessionInterruptionNotification object:nil];
    }
    return self;
}

-(void)dealloc
{
    [[AVAudioSession sharedInstance] setActive:NO error:nil];
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
    _playbackTimer = [NSTimer scheduledTimerWithTimeInterval:0.01f target:self selector:@selector(progressTimerUpdate) userInfo:nil repeats:YES];
    [_delegate voicemailAudioPlayer:self didChangePlaybackState:_player.isPlaying];
}

-(void)playAtTime:(NSTimeInterval)timeInterval
{
    NSTimeInterval time = MIN(MAX(0, timeInterval), _player.duration);
    _player.currentTime = time;
}

-(void)pause {
    [_player pause];
    [_delegate voicemailAudioPlayer:self didChangePlaybackState:_player.isPlaying];
    [self stopProgressTimer];
}

-(void)stop {
    if (!_player.isPlaying) {
        return;
    }
    
    [_player stop];
    [_delegate voicemailAudioPlayer:self didChangePlaybackState:_player.isPlaying];
    [self stopProgressTimer];
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

-(void)setSliderValue:(float)position{
    NSTimeInterval startTime =  (MIN(position, 1.0f) * _player.duration);
    [_player playAtTime: startTime];
}

#pragma mark - Notification Handlers

/**
 * Notification when the audio route has changes. This occures the input/output has changed, and is 
 * an opportunity for use to check to see if the output port contains the speaker to update the UI.
 */
-(void)audioSessionRouteChangeSelector:(NSNotification *)notification
{
    [_delegate voicemailAudioPlayer:self didChangeToSpeaker:self.speaker];
}

/**
 * Notification that our audio playback was being interupted by an external audio event, which we 
 * automatically pause our voicemail playback.
 */
-(void)audioSessionInteruptionSelector:(NSNotification *)notification
{
    [self pause];
}

#pragma mark - Delegate Handler -

-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    [_delegate voicemailAudioPlayer:self didChangePlaybackState:_player.isPlaying];
    [self stopProgressTimer];
}

-(void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error
{
    [_delegate voicemailAudioPlayer:self didFailWithError:error];
    [self stopProgressTimer];
}

#pragma mark - Private -

-(void)stopProgressTimer
{
    [_playbackTimer invalidate];
    _playbackTimer = nil;
    [self progressTimerUpdate];
}

-(void)progressTimerUpdate
{
    [_delegate voicemailAudioPlayer:self didUpdateProgress:_player.currentTime duration:_player.duration];
}


@end
