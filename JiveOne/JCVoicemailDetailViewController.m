//
//  JCVoicemailDetailViewController.m
//  JiveOne
//
//  Created by P Leonard on 5/7/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCVoicemailDetailViewController.h"
#import "JCDrawing.h"

// Models
#import "JCVoicemailAudioPlayer.h"
#import "VoicemailTranscription.h"

// Clients
#import "Voicemail+V5Client.h"

@interface JCVoicemailDetailViewController () <JCVoicemailAudioPlayerDelegate>
{
    JCVoicemailAudioPlayer *_player;
}

@end

@implementation JCVoicemailDetailViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Populate UI Data.
    Voicemail *voicemail = self.voicemail;
    self.title = voicemail.titleText;
    self.name.text = voicemail.name;
    self.number.text = voicemail.formattedNumber;
    self.date.text = voicemail.formattedLongDate;
    self.duration.text = [self formatSeconds:voicemail.duration];
    
    VoicemailTranscription *transcription = self.voicemail.transcription;
    self.voicemailTranscription.text = transcription.text;
    
    NSNumberFormatter *percent = [[NSNumberFormatter alloc] init];
    [percent setNumberStyle:NSNumberFormatterPercentStyle];
    [percent setMaximumFractionDigits:2];
   
    self.transcriptionConfidence.text = [NSString stringWithFormat:self.transcriptionConfidence.text, [percent stringFromNumber:[NSNumber numberWithFloat:transcription.confidence]]];
    self.transcriptionWordCount.text  = [NSString stringWithFormat:self.transcriptionWordCount.text, transcription.wordCount];
    
    // If we have the voicemail data, load the player and prepare for playback.
    if (voicemail.data.length > 0) {
        _player = [[JCVoicemailAudioPlayer alloc] initWithVoicemail:voicemail delegate:self];
        return;
    }
    
    // If we do not have voicemail data, use the v5 client to download the voicemail data. Disable
    // parts of the UI to show user it is unavailable for playback until downloaded.
    self.playPauseButton.enabled = FALSE;
    [self showStatus:NSLocalizedString(@"Downloading...", nil)];
    [voicemail downloadVoicemailAudio:^(BOOL success, NSError *error) {
        if (success) {
            [self hideStatus];
            _player = [[JCVoicemailAudioPlayer alloc] initWithVoicemail:voicemail delegate:self];
            self.playPauseButton.enabled = TRUE;
        } else {
            [self showError:error];
        }
    }];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.voicemail markAsRead:NULL];
}

#pragma mark - IBActions -

- (IBAction)playPauseButtonTapped:(id)sender
{
    [_player playPause];
}

- (IBAction)progressSliderMoved:(id)sender
{
    if([sender isKindOfClass:[UISlider class]])
    {
        UISlider *slider = (UISlider *)sender;
        NSTimeInterval value = slider.value;
        [_player playAtTime:value];
    }
}

- (IBAction)speakerTouched:(id)sender {
    _player.speaker = !_player.speaker;
}

#pragma mark - Delegate Handlers -

-(IBAction)deleteVoicemail:(id)sender
{
    if (_delegate && [_delegate respondsToSelector:@selector(voicemailDetailViewControllerDidDeleteVoicemail:)]) {
        [_delegate voicemailDetailViewControllerDidDeleteVoicemail:self];
    }
    
    [self.voicemail markForDeletion:^(BOOL success, NSError *error) {
        if (error) {
            [self showError:error];
        }
    }];
}

-(void)voicemailAudioPlayer:(JCVoicemailAudioPlayer *)player didLoadWithDuration:(NSTimeInterval)duration
{
    self.playPauseButton.enabled = TRUE;
    self.slider.enabled = TRUE;
    self.slider.minimumValue = 0.0f;
    self.slider.maximumValue = duration;
    
    NSString *durationText = [self formatSeconds:duration];
    self.duration.text = durationText;
    self.playerDuration.text = durationText;
}

-(void)voicemailAudioPlayer:(JCVoicemailAudioPlayer *)player didChangePlaybackState:(BOOL)playing
{
    self.playPauseButton.paused = !playing;
}

-(void)voicemailAudioPlayer:(JCVoicemailAudioPlayer *)player didFailWithError:(NSError *)error
{
    self.playPauseButton.enabled = FALSE;
    self.slider.enabled = FALSE;
    [self showError:error];
    self.playPauseButton.selected = player.isPlaying;
}

-(void)voicemailAudioPlayer:(JCVoicemailAudioPlayer *)player didChangeToSpeaker:(BOOL)speaker
{
    self.speakerButton.selected = speaker;
}

-(void)voicemailAudioPlayer:(JCVoicemailAudioPlayer *)player didUpdateProgress:(NSTimeInterval)currentTime duration:(NSTimeInterval)duration
{
    self.slider.value = currentTime;
}

#pragma mark - Private -

/** Time formatting helper fn: N seconds => M:SS */
-(NSString *)formatSeconds:(NSTimeInterval)seconds
{
    NSInteger minutes = (NSInteger)(seconds/60.);
    NSInteger remainingSeconds = (NSInteger)seconds % 60;
    return [NSString stringWithFormat:@"%.1ld:%.2ld",(long)minutes,(long)remainingSeconds];
}

@end
