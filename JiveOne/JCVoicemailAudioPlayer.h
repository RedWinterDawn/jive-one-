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

-(instancetype)initWithVoicemail:(Voicemail *)voicemail;

@property (nonatomic, weak) id<JCVoicemailAudioPlayerDelegate> delegate;
@property (nonatomic) BOOL speaker;

@property (nonatomic, readonly) BOOL isPlaying;

-(void)playPause;

//-(void)setSliderValue:(float)position;
//-(void)getSliderPosition:(float)position;

@end


@protocol JCVoicemailAudioPlayerDelegate <NSObject>

-(void)voicemailAudioPlayer:(JCVoicemailAudioPlayer *)player didChangeToSpeaker:(BOOL)speaker;

-(void)didStartPlayback:(JCVoicemailAudioPlayer *)player;
-(void)didPausePlayback:(JCVoicemailAudioPlayer *)player;
-(void)didStopPlayback:(JCVoicemailAudioPlayer *)player;

//-(void)voicemailPlayTapped:(BOOL)play;
//-(void)voicemailSliderMoved:(float)value;
//-(void)voicemailSliderTouched:(BOOL)touched;
//-(void)voicemailSpeakerTouched;
//-(void)voicemailAudioAvailable:(BOOL)available;
//-(void)voicemailDeleteTapped:(BOOL)deletePressed;

@end