//
//  JCVoicemailAudioPlayer.h
//  JiveOne
//
//  Created by P Leonard on 5/11/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "Voicemail+V5Client.h"

@class JCVoicemailAudioPlayer;
@protocol JCVoicemailAudioPlayerDelegate <NSObject>

-(void)didStartPlayback:(JCVoicemailAudioPlayer *)player;
-(void)didPausePlayback:(JCVoicemailAudioPlayer *)player;

-(void)voicemailPlayTapped:(BOOL)play;
-(void)voicemailSliderMoved:(float)value;
-(void)voicemailSliderTouched:(BOOL)touched;
-(void)voicemailSpeakerTouched;
-(void)voicemailAudioAvailable:(BOOL)available;
-(void)voicemailDeleteTapped:(BOOL)deletePressed;

@end

@interface JCVoicemailAudioPlayer : NSObject <AVAudioPlayerDelegate>

@property (nonatomic, readonly) BOOL isPlaying;

-(void)playPause;

-(instancetype)initWithVoicemail:(Voicemail *)voicemail;

@property (nonatomic, weak) id<JCVoicemailAudioPlayerDelegate> delegate;

-(void)setSliderValue:(float)position;

@end
