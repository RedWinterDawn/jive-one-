//
//  JCVoiceMailCell.m
//  Jive
//
//  Created by Aneil Mallavarapu on 10/19/13.
//  Copyright (c) 2013 Jive Communications. All rights reserved.
//

#import "JCVoicemailCell.h"
#import <AVFoundation/AVFoundation.h>

@interface JCVoicemailCell ()
@property (nonatomic,strong) AVAudioPlayer *audioPlayer;
@property (nonatomic,strong) NSTimer *progressTimer;
@end

@implementation JCVoicemailCell

#pragma mark - JCRecentItemCellProtocol
+(CGFloat)cellHeightForData:(id)data selected:(BOOL)selected {
    return selected ? 180 : 55;
}

+(NSString *)reuseIdentifier {
    return @"VoicemailCell";
}

-(void)configureWithItem:(Voicemail *)item andDelegate:(id)delegate{
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.username.text = item.callerId;
    
    // Relative date formatting:  e.g., Today, 1:55 PM
//    NSDateFormatter *df = [[NSDateFormatter alloc] init];
//    df.dateStyle = NSDateFormatterMediumStyle;
//    df.timeStyle = NSDateFormatterShortStyle;
//    df.doesRelativeDateFormatting = YES;
    self.creationTime.text = item.origdate;
    
    self.voicemailObject = item;
    self.delegate = delegate;
    
    [self setupAudioPlayer];
}

-(void)dealloc {
    [self.audioPlayer stop];
    self.audioPlayer = nil;
}

#pragma mark - ProgressBar
-(void)startProgressTimer {
    // !am! It would have been nicer to observe audioPlayer.currentTime, but that doesn't seem to work.
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
    self.progressView.progress = self.audioPlayer.currentTime / self.audioPlayer.duration;
}

#pragma mark - AVAudioPlayer
-(void)setupAudioPlayer {
    if (self.voicemailObject.message) {
        NSError *error;
        self.audioPlayer = [[AVAudioPlayer alloc] initWithData:self.voicemailObject.message fileTypeHint:@"m4a" error:&error];
        self.audioPlayer.delegate = self;
        _useSpeaker = NO;
        if (error) {
        }
        else {
            [self.audioPlayer prepareToPlay];
            self.progressView.progress = 0;
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
    return [NSString stringWithFormat:@"%.2d:%.2d",minutes,remainingSeconds];
}

#pragma mark Audio player public methods
-(void)stop {
    if (self.audioPlayer.isPlaying) {
        [self.audioPlayer stop];
        [self stopProgressTimer];
    }
}

-(void)pause {
    if (self.audioPlayer.isPlaying) {
        [self.audioPlayer pause];
        [self stopProgressTimer];
    }
}

-(void)play {
    [self setupSpeaker:self.useSpeaker];
    [self.audioPlayer play];
    [self startProgressTimer];
}

-(BOOL)isPlaying {
    return self.audioPlayer.isPlaying;
}

-(void)setUseSpeaker:(BOOL)useSpeaker {
    _useSpeaker = useSpeaker;
    [self setupSpeaker:useSpeaker];
}

#pragma mark - Actions
-(IBAction)toggleTapped:(id)sender {
    
    [self.delegate voiceCellToggleTapped:self];
}

-(IBAction)playTapped:(id)sender {
    
    [self.delegate voiceCellPlayTapped:self];
}

-(IBAction)infoTapped:(id)sender {
    
    [self.delegate voiceCellInfoTapped:self];
}

-(IBAction)archiveTapped:(id)sender {
    
    [self.delegate voiceCellArchiveTapped:self];
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

