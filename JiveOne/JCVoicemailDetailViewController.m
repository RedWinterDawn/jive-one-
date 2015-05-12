//
//  JCVoicemailDetailViewController.m
//  JiveOne
//
//  Created by P Leonard on 5/7/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCVoicemailDetailViewController.h"

#import "JCAppDelegate.h"
#import "JCVoicemailAudioPlayer.h"
#import "Voicemail+V5Client.h"
#import "JCPopoverSlider.h"
#import "JCSpeakerButton.h"
#import "JCPlayPauseButton.h"

#import "JCVoicemailAudioPlayer.h"

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
    
    Voicemail *voicemail = self.voicemail;
    self.title = voicemail.titleText;
    
    self.name.text = voicemail.name;
    self.number.text = voicemail.formattedNumber;
    self.date.text = voicemail.formattedLongDate;
    self.duration.text = [self formatSeconds:voicemail.duration];
    
    // If we have the voicemail data, load the player and prepare for playback.
    if (voicemail.data) {
        _player = [[JCVoicemailAudioPlayer alloc] initWithVoicemail:voicemail delegate:self];
        return;
    }
    
    
    
    // If we do not have voicemail data, use the v5 client to download the voicemail data. Disable
    // parts of the UI to show user it is unavailable for playback until downloaded.
    self.playPauseButton.enabled = FALSE;
    [self.spinningWheel startAnimating];
    
    [voicemail downloadVoicemailAudio:^(BOOL success, NSError *error) {
        if (success) {
            //[self.spinningWheel stopAnimating];
            _player = [[JCVoicemailAudioPlayer alloc] initWithVoicemail:voicemail delegate:self];
            self.playPauseButton.enabled = TRUE;
        } else {
            [self showError:error];
        }
    }];
}

//-(void)UpdateProgress:(NSNotification*)notification {
//    if (self.playPauseButton.selected == FALSE && player.isPlaying){
//        self.playPauseButton.selected = TRUE;
//    }
//    self.duration.text = [self formatSeconds:player.duration];
//    [self setSliderValue:player.currentTime];
//    [self.slider updateThumbWithCurrentProgress];
//}

-(void)dealloc
{
    if(self.voicemail){
        [self.voicemail removeObserver:self forKeyPath:kVoicemailDataAttributeKey];
    }
}

#pragma mark - Methods -

- (void)setSliderValue:(float)value
{
    self.slider.value = value;
}

#pragma mark - IBActions -

- (IBAction)playPauseButtonTapped:(id)sender
{
    if ([sender isKindOfClass:[UIButton class]]) {
        UIButton *button = (UIButton *)sender;
        button.selected = !button.selected;
        
        // TODO: Tell player to start playback
        
    }
}

- (IBAction)progressSliderMoved:(id)sender
{
    if([sender isKindOfClass:[UISlider class]])
    {
        UISlider *slider = (UISlider *)sender;
        float value = slider.value;
        
        // TODO: set the current time of the player to the value.
    }
}

- (IBAction)progressSliderTouched:(id)sender
{
    
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



#pragma mark - Private -

/** Time formatting helper fn: N seconds => M:SS */
-(NSString *)formatSeconds:(NSTimeInterval)seconds
{
    NSInteger minutes = (NSInteger)(seconds/60.);
    NSInteger remainingSeconds = (NSInteger)seconds % 60;
    return [NSString stringWithFormat:@"%.1ld:%.2ld",(long)minutes,(long)remainingSeconds];
}


@end
