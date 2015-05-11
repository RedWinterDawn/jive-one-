//
//  JCVoicemailAudioPlayer.h
//  JiveOne
//
//  Created by P Leonard on 5/11/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "Voicemail+V5Client.h"

@class JCVoicemailDetailViewPlayback;
@protocol JCVoicemailPlayerDelegate <NSObject>

-(void)voicemailPlayTapped:(BOOL)play;
-(void)voicemailSliderMoved:(float)value;
-(void)voicemailSliderTouched:(BOOL)touched;
-(void)voicemailSpeakerTouched;
-(void)voicemailAudioAvailable:(BOOL)available;
-(void)voicemailDeleteTapped:(BOOL)deletePressed;

@end

@interface JCVoicemailAudioPlayer : AVAudioPlayer<AVAudioPlayerDelegate>

@property (strong, nonatomic) Voicemail *voicemail;

-(void)setSliderValue:(float)position;
-(BOOL)getIsPlaying;

@end
