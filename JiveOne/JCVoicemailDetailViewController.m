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

#import "Voicemail+V5Client.h"
#import "JCPopoverSlider.h"
#import "JCSpeakerButton.h"
#import "JCPlayPauseButton.h"

@interface JCVoicemailDetailViewController () <JCVoicemailDetailDelegate>
{
    NSData *soundData;
    AVAudioPlayer *player;
    NSManagedObjectContext *context;
    BOOL _playThroughSpeaker;
    NSTimer *requestTimeout;
}
@property (nonatomic, retain) NSTimer *progressTimer;
@end

@implementation JCVoicemailDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.slider.minimumValue = 0.0;
    
    //Loading Indicator

   
    [self.voicemail addObserver:self forKeyPath:kVoicemailDataAttributeKey options:NSKeyValueObservingOptionNew context:NULL];
    if(self.voicemail.data.length > 0) {
        [self.spinningWheel stopAnimating];
        self.playPauseButton.enabled = true;
    }
    else {
        [self.spinningWheel startAnimating];
        self.playPauseButton.enabled = false;
    }
    
    self.title = _voicemail.titleText;
    if (self.playPauseButton.isSelected)
        self.playPauseButton.selected = [player isPlaying];
    self.speakerButton.selected = _playThroughSpeaker;
    [self updateTimer];
  
    self.nameLabel.text = _voicemail.titleText;
    [self reloadInputViews];
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
        if (self.delegate && [self.delegate respondsToSelector:@selector(voiceDetailPlayTapped:)]) {
            [self.delegate voiceDetailPlayTapped:self];
        }
    }
}

- (IBAction)progressSliderMoved:(id)sender
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(sliderMoved:)]) {
        [self.delegate sliderMoved:self.slider.value];
    }
}

- (IBAction)progressSliderTouched:(id)sender
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(sliderTouched:)]) {
        [self.delegate sliderTouched:YES];
    }
}

- (IBAction)speakerTouched:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(voiceSpeakerTouched)]) {
        [self.delegate voiceSpeakerTouched];
    }
}

-(IBAction)voiceCellDeleteTapped:(id)sender
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(voiceDeleteTapped:)]) {
        [self.delegate voiceDeleteTapped:self];
    }
}

-(void)voiceDeleteTapped:(BOOL)deletePressed{
    [self delete:self.voicemail];
    [self dismissViewControllerAnimated:NO completion:NULL];
}
#pragma mark - JCVoicemailDelegate
-(void)voiceDetailPlayTapped:(BOOL)play{
    [self playPauseAudio];
}

-(void)sliderMoved:(float)value {
    player.currentTime = value;
    [self updateTimer];
    [self startProgressTimerForVoicemail];
}

-(void)sliderTouched:(BOOL)touched
{
    [self stopProgressTimerForVoicemail];
}

-(void)voiceSpeakerTouched  {
    _playThroughSpeaker = !_playThroughSpeaker;
    self.speakerButton.selected =_playThroughSpeaker;
    [self setupSpeaker];
}

-(void)voiceMailAudioAvailable:(BOOL)available  {
    if(player && player.isPlaying)  {
        [player stop];
    }
    NSError *error;
    player = [[AVAudioPlayer alloc] initWithData:self.voicemail.data fileTypeHint:AVFileTypeWAVE error:&error];
    if (player) {
        [self setupSpeaker];
        player.delegate = self;
        [player prepareToPlay];
        [self updateViewForPlayerInfo];
    }
}

-(void)playPauseAudio {
    BOOL playing = player.isPlaying;
    
    if (playing) {
        //Pause
        [player pause];
        
        [self stopProgressTimerForVoicemail];
        self.playPauseButton.selected = FALSE;
        [UIDevice currentDevice].proximityMonitoringEnabled = NO;
    }
    else {
        //Play
        [player play];
        [self startProgressTimerForVoicemail];
        self.playPauseButton.selected = TRUE;
        [self.voicemail markAsRead:NULL];
        [UIDevice currentDevice].proximityMonitoringEnabled = YES;
    }
}

-(void) updateViewForPlayerInfo
{
   self.duration.text = [NSString stringWithFormat:@"%d:%02d", (int)player.duration/60, (int)player.duration % 60, nil];
    self.slider.maximumValue = player.duration;
}

-(void)startProgressTimerForVoicemail   {
    if (player.isPlaying) {
        if(self.progressTimer) {
            [self stopProgressTimerForVoicemail];
        }
        self.progressTimer = [NSTimer scheduledTimerWithTimeInterval:.01 target:self selector:@selector(UpdateProgress:) userInfo:nil repeats:YES];
    }
}

-(void)stopProgressTimerForVoicemail {
    [self.progressTimer invalidate];
    self.progressTimer = nil;
}

-(void)UpdateProgress:(NSNotification*)notification {
    if (self.playPauseButton.selected == FALSE && player.isPlaying){
        self.playPauseButton.selected = TRUE;
    }
    self.duration.text = [self formatSeconds:player.duration];
    [self setSliderValue:player.currentTime];
    [self.slider updateThumbWithCurrentProgress];
    
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


- (void)setupSpeaker
{
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError *error;
    
    // set category PlanAndRecord in order to be able to use AudioRoueOverride
    [session setCategory:AVAudioSessionCategoryPlayAndRecord
                   error:&error];
    
    AVAudioSessionPortOverride portOverride = _playThroughSpeaker ? AVAudioSessionPortOverrideSpeaker : AVAudioSessionPortOverrideNone;
    [session overrideOutputAudioPort:portOverride error:&error];
    
    if (!error) {
        [session setActive:YES error:&error];
        
        if (!error) {
            if (_playThroughSpeaker) {
                self.speakerButton.selected = YES;
            }
            else {
                self.speakerButton.selected = NO;
            }
        }
    }
}


@end
