//
//  JCVoicemailDetailViewController.m
//  JiveOne
//
//  Created by P Leonard on 5/7/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCVoicemailDetailViewController.h"

#import "JCSpeakerButton.h"
#import "JCPlayPauseButton.h"
#import "JCVoicemailAudioPlayer.h"

#import "Voicemail+V5Client.h"
#import "VoicemailTranscription.h"

@interface JCVoicemailDetailViewController () <JCVoicemailAudioPlayerDelegate>
{
    JCVoicemailAudioPlayer *_player;
}

@end

NSString *const  kConfidenceLabelPreText = @"Confidence";
NSString *const kWordCountLabelPreText = @"Word count";

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
   
    
    self.transcriptionConfidence.text = [NSString stringWithFormat:@"%@: %@", NSLocalizedString(kConfidenceLabelPreText, nil) , [percent stringFromNumber:[NSNumber numberWithFloat:transcription.confidence]]];
    
    NSNumber *wordcountNumber = [NSNumber numberWithLong:transcription.wordCount];
    
    self.transcriptionWordCount.text = [NSString stringWithFormat:@"%@: %@", NSLocalizedString(kWordCountLabelPreText, nil), wordcountNumber];
    
    
    // If we have the voicemail data, load the player and prepare for playback.
    if (voicemail.data.length > 0) {
        _player = [[JCVoicemailAudioPlayer alloc] initWithVoicemail:voicemail delegate:self];
        return;
    }
    
    // If we do not have voicemail data, use the v5 client to download the voicemail data. Disable
    // parts of the UI to show user it is unavailable for playback until downloaded.
    self.playPauseButton.enabled = FALSE;
    [self showStatus:@"Downloading..."];
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

#pragma mark - Methods -

- (void)setSliderValue:(float)value
{
    self.slider.value = value;
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

- (IBAction)progressSliderTouched:(id)sender
{
    [_player pause];
    
    
//    if([sender isKindOfClass:[UISlider class]])
//    {
//        UISlider *slider = (UISlider *)sender;
//        NSTimeInterval value = slider.value;
//        [_player playAtTime:value];
//    }
}

- (IBAction)speakerTouched:(id)sender {
    BOOL speaker = _player.speaker;
    _player.speaker = !speaker;
}

#pragma mark - Delegate Handlers -

-(IBAction)deleteVoicemail:(id)sender
{
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        Voicemail *localVoicemail = (Voicemail *)[localContext objectWithID:self.voicemail.objectID];
        [localContext deleteObject:localVoicemail];
    } completion:^(BOOL success, NSError *error) {
        
    }];
}

-(void)voicemailAudioPlayer:(JCVoicemailAudioPlayer *)player didLoadWithDuration:(NSTimeInterval)duration
{
    self.playPauseButton.enabled = TRUE;
    self.slider.enabled = TRUE;
    self.slider.minimumValue = 0.0f;
    self.slider.maximumValue = duration;
    self.duration.text = [self formatSeconds:duration];
}

-(void)voicemailAudioPlayer:(JCVoicemailAudioPlayer *)player didChangePlaybackState:(BOOL)playing
{
    self.playPauseButton.selected = playing;
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
    [self.slider updateThumbWithCurrentProgress];
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
