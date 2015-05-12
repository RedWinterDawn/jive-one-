//
//  JCVoicemailDetailViewController.m
//  JiveOne
//
//  Created by P Leonard on 5/7/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCVoicemailDetailViewController.h"
#import "JCV5ApiClient.h"


#import "JCAppDelegate.h"
#import "JCVoicemailAudioPlayer.h"
#import "Voicemail+V5Client.h"
#import "JCPopoverSlider.h"
#import "JCSpeakerButton.h"
#import "JCPlayPauseButton.h"

@implementation JCVoicemailDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.slider.minimumValue = 0.0;
    self.slider.maximumValue = 1.0;
    
    // TODO: Make sure the voicemail data is loaded from the V5 api client.
    
    //[self.voicemail addObserver:self forKeyPath:kVoicemailDataAttributeKey options:NSKeyValueObservingOptionNew context:NULL];
    /*if(self.voicemail.data.length > 0) {
        [self.spinningWheel stopAnimating];
        self.playPauseButton.enabled = true;
    }
    else {
        [self.spinningWheel startAnimating];
        self.playPauseButton.enabled = false;
    }*/
    
    self.title = _voicemail.titleText;
//    if (self.playPauseButton.isSelected)
//        self.playPauseButton.selected = [player isPlaying];
//    self.speakerButton.selected = _playThroughSpeaker;
//  
    //self.nameLabel.text = _voicemail.titleText;
//    [self reloadInputViews];
}

-(void) updateViewForPlayerInfo
{
//    self.duration.text = [NSString stringWithFormat:@"%d:%02d", (int)player.duration/60, (int)player.duration % 60, nil];
//    self.slider.maximumValue = vmailPlayer.duration;
}

-(void)startProgressTimerForVoicemail   {
//    if (player.isPlaying) {
//        if(self.progressTimer) {
//            [self stopProgressTimerForVoicemail];
//        }
//        self.progressTimer = [NSTimer scheduledTimerWithTimeInterval:.01 target:self selector:@selector(UpdateProgress:) userInfo:nil repeats:YES];
//    }
}

-(void)stopProgressTimerForVoicemail {
//    [self.progressTimer invalidate];
//    self.progressTimer = nil;
}

-(void)UpdateProgress:(NSNotification*)notification {
//    if (self.playPauseButton.selected == FALSE && player.isPlaying){
//        self.playPauseButton.selected = TRUE;
//    }
//    self.duration.text = [self formatSeconds:player.duration];
//    [self setSliderValue:player.currentTime];
//    [self.slider updateThumbWithCurrentProgress];

}




/** Time formatting helper fn: N seconds => M:SS */
-(NSString *)formatSeconds:(NSTimeInterval)seconds {
    NSInteger minutes = (NSInteger)(seconds/60.);
    NSInteger remainingSeconds = (NSInteger)seconds % 60;
    return [NSString stringWithFormat:@"%.1ld:%.2ld",(long)minutes,(long)remainingSeconds];
}
-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag  {
    [self stopProgressTimerForVoicemail];
    self.playPauseButton.selected = FALSE;
    [UIDevice currentDevice].proximityMonitoringEnabled = NO;
}

-(void) audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error   {
    [self stopProgressTimerForVoicemail];
    self.playPauseButton.selected = TRUE;
    [UIDevice currentDevice].proximityMonitoringEnabled = YES;
}


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
    
}

-(IBAction)voiceCellDeleteTapped:(id)sender
{
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        Voicemail *localVoicemail = (Voicemail *)[localContext objectWithID:self.voicemail.objectID];
        [localContext deleteObject:localVoicemail];
    } completion:^(BOOL success, NSError *error) {
        
    }];
}

#pragma mark - JCVoicemailDelegate
-(void)voiceDetailPlayTapped:(BOOL)play{
    
//    [self playPauseAudio];
}

-(void)sliderTouched:(BOOL)touched
{
//    [self stopProgressTimerForVoicemail];
}

-(void)voiceSpeakerTouched  {
//    _playThroughSpeaker = !_playThroughSpeaker;
//    self.speakerButton.selected =_playThroughSpeaker;
//    [self setupSpeaker];
}

@end
