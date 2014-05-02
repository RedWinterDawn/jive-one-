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
{
    int count;
}
-(Voicemail*)getVoicemailObject{
    return _voicemailObject;
}


+(CGFloat)cellHeightForData:(id)data selected:(BOOL)selected {
    return selected ? 300 : 60;
}

+(NSString *)reuseIdentifier {
    return @"VoicemailCell";
}

-(void)configureWithItem:(Voicemail *)item andDelegate:(id)delegate{
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleTapped:)];
    [self addGestureRecognizer:tapGestureRecognizer];
    [self.slider setThumbImage:[UIImage imageNamed:@"thumb1.png"] forState:UIControlStateNormal];
    self.selectionStyle = UITableViewCellSelectionStyleNone;

    
    if(!item.callerName){
        self.callerId.text = item.callerNumber;
        self.phone_state.text = @"Utah";
    }else{
        self.callerId.text = item.callerName;
        self.phone_state.text = [NSString stringWithFormat:@"%@ Utah", item.callerNumber];
    }
    self.userImage.image = [UIImage imageNamed:@"avatar.png"];
  

    self.shortTime.text = [Common shortDateFromTimestamp:[NSNumber numberWithLongLong:[item.createdDate longLongValue]]];
    self.creationTime.text = [Common longDateFromTimestamp:[NSNumber numberWithLongLong:[item.createdDate longLongValue]]];
    self.duration.text = [self formatSeconds:[item.lenght doubleValue]];
    self.voicemailObject = item;
    self.delegate = delegate;
    
    //test to see if we have already downloaded the voicemail .wav file
    if (self.voicemailObject.voicemail.length > 0) {
        // if the activityIndicator is visible
        if (![self.spinningWheel isHidden]) {
            [self.spinningWheel performSelectorOnMainThread:@selector(stopAnimating) withObject:nil waitUntilDone:NO];
            //stopAnimating should also hide the activity indicator
        }
    }
//    theImageView.image = [theImageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
//    [theImageView setTintColor:[UIColor redColor]];
    
    [self.voicemailObject addObserver:self forKeyPath:kVoicemailKeyPathForVoicemal options:NSKeyValueObservingOptionNew context:NULL];
    
    if(![self.voicemailObject.read boolValue]){
        
        self.shortTime.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:14];
        self.creationTime.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:14];
        self.callerId.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:16];
        self.phone_state.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:14];
        self.voicemailIcon.image = [self.voicemailIcon.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [self.voicemailIcon setTintColor:[UIColor redColor]];
    }else{
        self.shortTime.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14];
        self.creationTime.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14];
        self.callerId.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
        self.phone_state.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14];
        self.voicemailIcon.image = [self.voicemailIcon.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [self.voicemailIcon setTintColor:[UIColor blackColor]];
    }
    
    [self setupAudioPlayer];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:kVoicemailKeyPathForVoicemal]) {
        Voicemail *voicemail = (Voicemail *)object;
        
        if (voicemail && voicemail.voicemailId != nil && voicemail.urn != nil && voicemail.file != nil) {
            self.voicemailObject = voicemail;
            
            [self performSelectorOnMainThread:@selector(setupAudioPlayer) withObject:nil waitUntilDone:NO];
            [self.spinningWheel performSelectorOnMainThread:@selector(stopAnimating) withObject:nil waitUntilDone:NO];
        }
    }
}

-(void)dealloc {
    [self.audioPlayer stop];
    self.audioPlayer = nil;
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

#pragma mark Custom Swipe delete icon
-(void)willTransitionToState:(UITableViewCellStateMask)state{
    NSLog(@"EventTableCell willTransitionToState");
    [super willTransitionToState:state];
    if((state & UITableViewCellStateShowingDeleteConfirmationMask) == UITableViewCellStateShowingDeleteConfirmationMask){
        [self recurseAndReplaceSubViewIfDeleteConfirmationControl:self.subviews];
        [self performSelector:@selector(recurseAndReplaceSubViewIfDeleteConfirmationControl:) withObject:self.subviews afterDelay:0];
    }
}
-(void)recurseAndReplaceSubViewIfDeleteConfirmationControl:(NSArray*)subviews{
    NSString *delete_button_name = @"vm-delete.png";
    for (UIView *subview in subviews)
    {
        //handles ios6 and earlier
        if ([NSStringFromClass([subview class]) isEqualToString:@"UITableViewCellDeleteConfirmationControl"])
        {
            //we'll add a view to cover the default control as the image used has a transparent BG
            UIView *backgroundCoverDefaultControl = [[UIView alloc] initWithFrame:CGRectMake(0,0, 64, 33)];
            [backgroundCoverDefaultControl setBackgroundColor:[UIColor whiteColor]];//assuming your view has a white BG
            [[subview.subviews objectAtIndex:0] addSubview:backgroundCoverDefaultControl];
            UIImage *deleteImage = [UIImage imageNamed:delete_button_name];
            UIImageView *deleteBtn = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0,deleteImage.size.width, deleteImage.size.height)];
            [deleteBtn setImage:[UIImage imageNamed:delete_button_name]];
            [[subview.subviews objectAtIndex:0] addSubview:deleteBtn];
        }
        //the rest handles ios7
        if ([NSStringFromClass([subview class]) isEqualToString:@"UITableViewCellDeleteConfirmationButton"])
        {
            UIButton *deleteButton = (UIButton *)subview;
            [deleteButton setImage:[UIImage imageNamed:delete_button_name] forState:UIControlStateNormal];
            [deleteButton setTitle:@"" forState:UIControlStateNormal];
            [deleteButton setBackgroundColor:[UIColor redColor]];
            for(UIView* view in subview.subviews){
                if([view isKindOfClass:[UILabel class]]){
                    [view removeFromSuperview];
                }
            }
        }
        if ([NSStringFromClass([subview class]) isEqualToString:@"UITableViewCellDeleteConfirmationView"])
        {
            for(UIView* innerSubView in subview.subviews){
                if(![innerSubView isKindOfClass:[UIButton class]]){
                    [innerSubView removeFromSuperview];
                }
            }
        }
        if([subview.subviews count]>0){
            [self recurseAndReplaceSubViewIfDeleteConfirmationControl:subview.subviews];
        }
        
    }
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
    [self.playButton setImage:[UIImage imageNamed:@"voicemail_scrub_play.png"] forState:UIControlStateNormal];
}

-(void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error {
    [self stopProgressTimer];
}
@end

