//
//  JCVoiceMailCell.m
//  Jive
//
//  Created by Doug Leonard on 4/18/14.
//  Copyright (c) 2013 Jive Communications. All rights reserved.
//

#import "JCVoicemailCell.h"
#import <AVFoundation/AVFoundation.h>
#import "Common.h"
#import "JCvoicemailViewController.h"

@interface JCVoicemailCell ()
@property (nonatomic,strong) AVAudioPlayer *audioPlayer;
@property (nonatomic,strong) NSTimer *progressTimer;
@end

@implementation JCVoicemailCell

+(CGFloat)cellHeightForSelectedState:(BOOL)selected {
    return selected ? 180 : 55;
}

+(NSString *)reuseIdentifier {
    return @"VoicemailCell";
}

-(void)configureWithItem:(Voicemail *)item andDelegate:(id)delegate{
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleTapped:)];
    [self addGestureRecognizer:tapGestureRecognizer];
    [self.slider setThumbImage:[UIImage imageNamed:@"thumb1.png"] forState:UIControlStateNormal];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.username.text = item.callerId;
    self.title.text = @"Voicemail";
    self.creationTime.text = [Common dateFromTimestamp:[NSNumber numberWithLongLong:[item.createdDate longLongValue]]];
    self.duration.text = [self formatSeconds:[item.duration doubleValue]];
    self.voicemailObject = item;
    self.delegate = delegate;
    
    
    if (self.voicemailObject.voicemail.length > 0) {
        [self.playButton setEnabled:YES];
    }else{
        [self.playButton setEnabled:NO];
    }
    
    [self.voicemailObject addObserver:self forKeyPath:kVoicemailKeyPathForVoicemal options:NSKeyValueObservingOptionNew context:NULL];
    [self.voicemailObject addObserver:self.delegate forKeyPath:kVoicemailKeyPathForVoicemal options:NSKeyValueObservingOptionNew context:NULL];
//    if(![self.voicemailObject.read boolValue]){
//        
//        self.username.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:14];
//        self.creationTime.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:14];
//        self.title.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:16];
//    }else{
//        self.username.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14];
//        self.creationTime.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14];
//        self.title.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
//    }
    
    [self setupAudioPlayer];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:kVoicemailKeyPathForVoicemal]) {
        Voicemail *voicemail = (Voicemail *)object;
        self.voicemailObject = voicemail;
        [self setupAudioPlayer];
    }
}

-(void)dealloc {
    [self.audioPlayer stop];
    self.audioPlayer = nil;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    self.expanded = selected;
//    [self setSelected:selected];
    // Configure the view for the selected state
}

#pragma mark - ProgressBar
-(void)startProgressTimer {
    // It would have been nicer to observe audioPlayer.currentTime, but that doesn't seem to work.
    if (self.progressTimer) {
        [self stopProgressTimer];
    }
    
    self.progressTimer = [NSTimer scheduledTimerWithTimeInterval:.05 target:self selector:@selector(updateProgress) userInfo:nil repeats:YES];
}

-(void)stopProgressTimer {
    [self.progressTimer invalidate];
    self.progressTimer = nil;
}

-(void)updateProgress {
    self.duration.text = [self formatSeconds:self.audioPlayer.duration];
    self.elapsed.text = [self formatSeconds:self.audioPlayer.currentTime];
//    self.progressView.progress = self.audioPlayer.currentTime / self.audioPlayer.duration;
    self.slider.value = self.audioPlayer.currentTime / self.audioPlayer.duration;
}

-(IBAction)progressSliderMoved:(UISlider*)sender
{
    self.audioPlayer.currentTime = (sender.value * self.audioPlayer.duration);
    [self updateProgress];
}


#pragma mark - AVAudioPlayer
-(void)setupAudioPlayer {
    if (self.voicemailObject.voicemail) {
        NSError *error;
        self.audioPlayer = [[AVAudioPlayer alloc] initWithData:self.voicemailObject.voicemail fileTypeHint:AVFileTypeWAVE error:&error];
        self.audioPlayer.delegate = self;
        _useSpeaker = NO;
        if (error) {
        }
        else {
            [self.audioPlayer prepareToPlay];
            self.slider.value = 0.0;
        }
    }
//    else {
//        [self.item loadMessage:^(NSError *error) {
//            if (error) {
//            }
//            else {
//                [self setupAudioPlayer];
//            }
//        }];
//    }
}

-(void)setupSpeaker:(BOOL)useSpeaker {
    // ONLY turns on the speaker right now...
    AVAudioSession *session = [AVAudioSession sharedInstance];
    BOOL success;
    NSError *error;
    success = [session setCategory:AVAudioSessionCategoryPlayAndRecord
                             error:&error];
    if (!success) {
    }
    else {
        AVAudioSessionPortOverride override = useSpeaker ? AVAudioSessionPortOverrideSpeaker : AVAudioSessionPortOverrideNone;
        success = [session overrideOutputAudioPort:override
                                             error:&error];
        if (!success)  {
        }
        
        //activate the audio session
        success = [session setActive:YES error:&error];
        if (!success) {
        }
        else {
        }
    }
}

/** Time formatting helper fn: N seconds => MM:SS */
-(NSString *)formatSeconds:(NSTimeInterval)seconds {
    NSInteger minutes = (NSInteger)(seconds/60.);
    NSInteger remainingSeconds = (NSInteger)seconds % 60;
    return [NSString stringWithFormat:@"%.2ld:%.2ld",(long)minutes,(long)remainingSeconds];
}

#pragma mark Audio player public methods
-(void)stop {
    if (self.audioPlayer.isPlaying) {
        [self.audioPlayer stop];
        [self stopProgressTimer];
        [self.playButton setImage:[UIImage imageNamed:@"voicemail_scrub_play.png"] forState:UIControlStateNormal];
    }
}

-(void)pause {
    if (self.audioPlayer.isPlaying) {
        [self.audioPlayer pause];
        [self stopProgressTimer];
        [self.playButton setImage:[UIImage imageNamed:@"voicemail_scrub_play.png"] forState:UIControlStateNormal];
    }
}

-(void)play {
    [self setupSpeaker:self.useSpeaker];
    [self.audioPlayer play];
    [self startProgressTimer];
    [self.playButton setImage:[UIImage imageNamed:@"voicemail_pause.png"] forState:UIControlStateNormal];
}

-(void)playAtTime:(NSInteger) time
{
    [self setupSpeaker:self.useSpeaker];
    [self.audioPlayer playAtTime:(time * self.audioPlayer.duration)];
    [self startProgressTimer];
}

-(BOOL)isPlaying {
    return self.audioPlayer.isPlaying;
}

-(void)setUseSpeaker:(BOOL)useSpeaker {
    _useSpeaker = useSpeaker;
    [self setupSpeaker:useSpeaker];
}

-(void)toggleTapped:(id)sender {
    [self.delegate voiceCellToggleTapped:self];
}

#pragma mark - Actions
-(IBAction)playTapped:(id)sender {
    
    [self.delegate voiceCellPlayTapped:self];
}


-(IBAction)infoTapped:(id)sender {
    
    [self.delegate voiceCellInfoTapped:self];
}

-(IBAction)deleteTapped:(id)sender {
    
    [self.delegate voiceCellDeleteTapped:self];
}

-(IBAction)replyTapped:(id)sender {
    
    [self.delegate voiceCellReplyTapped:self];
}

-(IBAction)speakerTapped:(id)sender {
    
    [self.delegate voiceCellSpeakerTapped:self];
}

#pragma mark - AVAudioPlayerDelegate
-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    [self stopProgressTimer];
}

-(void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error {
    [self stopProgressTimer];
}
@end

