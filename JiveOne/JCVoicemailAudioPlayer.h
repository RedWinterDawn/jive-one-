//
//  JCVoicemailAudioPlayer.h
//  JiveOne
//
//  Created by P Leonard on 5/11/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

@import AVFoundation;

#import "Voicemail.h"

@protocol JCVoicemailAudioPlayerDelegate;

@interface JCVoicemailAudioPlayer : NSObject

-(instancetype)initWithVoicemail:(Voicemail *)voicemail delegate:(id<JCVoicemailAudioPlayerDelegate>)delegate;

@property (nonatomic) BOOL speaker;
@property (nonatomic, readonly) BOOL isPlaying;

-(void)playPause;

-(void)play;
-(void)pause;
-(void)stop;

@end

@protocol JCVoicemailAudioPlayerDelegate <NSObject>

-(void)voicemailAudioPlayer:(JCVoicemailAudioPlayer *)player didLoadWithDuration:(NSTimeInterval)duration;
-(void)voicemailAudioPlayer:(JCVoicemailAudioPlayer *)player didChangePlaybackState:(BOOL)playing;
-(void)voicemailAudioPlayer:(JCVoicemailAudioPlayer *)player didChangeToSpeaker:(BOOL)speaker;
-(void)voicemailAudioPlayer:(JCVoicemailAudioPlayer *)player didFailWithError:(NSError *)error;

@end