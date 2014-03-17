//
//  AudioRecordingViewController.m
//  CRNAUA2
//
//  Created by Eduardo Gueiros on 11/13/13.
//  Copyright (c) All rights reserved.
//

#import "AudioRecordingViewController.h"
#include "Voicemail.h"
@interface AudioRecordingViewController ()
{
    NSURL* soundFileURL;
    NSString* soundFilePath;
    UIPopoverController *popoverController;
    ClientEntities *me;
}

@end

@implementation AudioRecordingViewController

void RouteChangeListener(	void *                  inClientData,
                         AudioSessionPropertyID	inID,
                         UInt32                  inDataSize,
                         const void *            inData);

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    _playButton.enabled = NO;
    _stopButton.enabled = NO;
    [_recordButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
    
    [self initPlayer];
    
    OSStatus result = AudioSessionInitialize(NULL, NULL, NULL, NULL);
	if (result)
		NSLog(@"Error initializing audio session! %d", (int)result);
	
	[[AVAudioSession sharedInstance] setDelegate: self];
	NSError *setCategoryError = nil;
	[[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback error: &setCategoryError];
	if (setCategoryError)
		NSLog(@"Error setting category! %@", setCategoryError);
	
	result = AudioSessionAddPropertyListener (kAudioSessionProperty_AudioRouteChange, RouteChangeListener, (__bridge void *)(self));
	if (result)
		NSLog(@"Could not add property listener! %d", (int)result);
}

#pragma mark - iPad, adjust popover view
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self forcePopoverSize];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    CGSize currentSetSizeForPopover = self.contentSizeForViewInPopover;
    self.contentSizeForViewInPopover = currentSetSizeForPopover;
}

- (void) forcePopoverSize {
    CGSize currentSetSizeForPopover = self.contentSizeForViewInPopover;
    CGSize fakeMomentarySize = CGSizeMake(currentSetSizeForPopover.width - 1.0f, currentSetSizeForPopover.height - 1.0f);
    self.contentSizeForViewInPopover = fakeMomentarySize;
}

#pragma mark - check if file exists
-(BOOL) checkFileExists
{
    NSString *docsDir;
    NSArray *dirPaths;
    
    dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    docsDir = [dirPaths objectAtIndex:0];
    NSString *databasePath = [[NSString alloc] initWithString: [docsDir stringByAppendingPathComponent:@"VoicemailTest.wav"]];
    
    
    soundFilePath = databasePath;
    
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:soundFilePath isDirectory:NO];
    if (fileExists) {
        _playButton.enabled = YES;
        _discardButton.enabled = YES;
        _progressSlider.enabled = YES;
    }
    else
    {
        _playButton.enabled = NO;
        _discardButton.enabled = NO;
        _progressSlider.enabled = NO;
        _progressSlider.value = 0.0;
        _currentTime.text = @"0.00";
        _durationTime.text = @"0.00";
    }
    
    return fileExists;
}

#pragma mark - init player and recorder

- (void)initPlayer
{
    NSArray *dirPaths;
    NSString *docsDir;
    
    dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    docsDir = dirPaths[0];
    
    soundFilePath = [docsDir stringByAppendingPathComponent:@"recording.wav"];
    
    [self checkFileExists];
    
    soundFileURL = [NSURL fileURLWithPath:soundFilePath];
    
    [self registerForBackgroundNotifications];
    
	_updateTimer = nil;
    _durationTime.adjustsFontSizeToFitWidth = YES;
	_currentTime.adjustsFontSizeToFitWidth = YES;
	_progressSlider.minimumValue = 0.0;
    
    _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:soundFileURL error:nil];
	if (_audioPlayer)
	{
		[self updateViewForPlayerInfo:_audioPlayer];
		[self updateViewForPlayerState:_audioPlayer];
		//player.numberOfLoops = 1;
		_audioPlayer.delegate = self;
	}
}

- (void)initRecorder
{
    if(!_audioRecorder){
        NSDictionary *recordSettings = [NSDictionary
                                        dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithInt:AVAudioQualityLow],
                                        AVEncoderAudioQualityKey,
                                        [NSNumber numberWithInt:8],
                                        AVEncoderBitRateKey,
                                        [NSNumber numberWithInt: 1],
                                        AVNumberOfChannelsKey,
                                        [NSNumber numberWithFloat:8000.0],
                                        AVSampleRateKey,
                                        nil];
        NSError *error = nil;
        
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord
                            error:nil];
        
        _audioRecorder = [[AVAudioRecorder alloc]
                          initWithURL:soundFileURL
                          settings:recordSettings
                          error:&error];
        
        if (error)
        {
            NSLog(@"error: %@", [error localizedDescription]);
        } else {
            [_audioRecorder prepareToRecord];
        }
    }
}

#pragma mark - update labels and progress bar

-(void)updateCurrentTimeForPlayer:(AVAudioPlayer *)p
{
	_currentTime.text = [NSString stringWithFormat:@"%d:%02d", (int)p.currentTime / 60, (int)p.currentTime % 60, nil];
    _progressSlider.value = p.currentTime;
}

- (void)updateCurrentTime
{
	[self updateCurrentTimeForPlayer:self.audioPlayer];
}

- (void)updateViewForPlayerState:(AVAudioPlayer *)p
{
	[self updateCurrentTimeForPlayer:p];
    
	if (_updateTimer)
		[_updateTimer invalidate];
    
	if (p.playing)
	{
		//[_playButton setImage:((p.playing == YES) ? pauseBtnBG : playBtnBG) forState:UIControlStateNormal];
        [_playButton setTitle:((p.playing == YES) ? @"Pause" : @"Play") forState:UIControlStateNormal];
		_updateTimer = [NSTimer scheduledTimerWithTimeInterval:.01 target:self selector:@selector(updateCurrentTime) userInfo:p repeats:YES];
	}
	else
	{
		//[playButton setImage:((p.playing == YES) ? pauseBtnBG : playBtnBG) forState:UIControlStateNormal];
        [_playButton setTitle:((p.playing == YES) ? @"Pause" : @"Play") forState:UIControlStateNormal];
		_updateTimer = nil;
	}
    
    [_recordButton setEnabled:!p.playing];
}

- (void)updateViewForPlayerStateInBackground:(AVAudioPlayer *)p
{
	[self updateCurrentTimeForPlayer:p];
	
	if (p.playing)
	{
		//[_playButton setImage:((p.playing == YES) ? pauseBtnBG : playBtnBG) forState:UIControlStateNormal];
        [_playButton setTitle:((p.playing == YES) ? @"Pause" : @"Play") forState:UIControlStateNormal];
        
	}
	else
	{
		//[_playButton setImage:((p.playing == YES) ? pauseBtnBG : playBtnBG) forState:UIControlStateNormal];
        [_playButton setTitle:((p.playing == YES) ? @"Pause" : @"Play") forState:UIControlStateNormal];
	}
    
    [_recordButton setEnabled:!p.playing];
}

-(void)updateViewForPlayerInfo:(AVAudioPlayer*)p
{
	_durationTime.text = [NSString stringWithFormat:@"%d:%02d", (int)p.duration / 60, (int)p.duration % 60, nil];
	_progressSlider.maximumValue = p.duration;
}

-(void)pausePlaybackForPlayer:(AVAudioPlayer*)p
{
	[p pause];
	[self updateViewForPlayerState:p];
}

-(void)startPlaybackForPlayer:(AVAudioPlayer*)p
{
	if ([p play])
	{
		[self updateViewForPlayerState:p];
	}
	else
		NSLog(@"Could not play %@\n", p.url);
}

-(void)startRecording
{
    [self initRecorder];
    _playButton.enabled = NO;
    _stopButton.enabled = YES;
    [_audioRecorder record];
    [_recordButton setTitle:@"Stop Recording" forState:UIControlStateNormal];
    [_recordButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    
    _recordingView.hidden = NO;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 60.0 * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void)
                   {
                       [_recordingView.layer removeAllAnimations];
                       _recordingView.alpha = 0.0; // Animation clean-up
                   });
    
    [UIView animateWithDuration:1.0 // 0.15*6=0.9: It will animate six times (three in reverse)
                          delay:0.0
                        options:UIViewAnimationOptionAutoreverse | UIViewAnimationOptionRepeat
                     animations:^{
                         _recordingView.alpha = 1.0; // Animation
                     }
                     completion:NULL];
}

-(void)deletePreviousAudio
{
    NSError *error;
    if ([[NSFileManager defaultManager] isDeletableFileAtPath:soundFilePath]) {
        BOOL success = [[NSFileManager defaultManager] removeItemAtPath:soundFilePath error:&error];
        if (!success) {
            NSLog(@"Error removing file at path: %@", error.localizedDescription);
        }
    }
    [self checkFileExists];
}

#pragma mark - Record, Play, Stop Actions

- (IBAction)recordAudio:(id)sender
{
    if (!_audioRecorder.recording)
    {
        if([self checkFileExists])
        {
            UIAlertView * fileExistsAlert = [[UIAlertView alloc] initWithTitle:@"Audio Exists" message:@"The new recording will erase the existing one. Would you like to continue?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
            fileExistsAlert.tag = 100;
            [fileExistsAlert show];
        }
        else
        {
            [self startRecording];
        }
    }
    else
    {
        [_audioRecorder stop];
        [_recordButton setTitle:@"Record" forState:UIControlStateNormal];
        _recordingView.hidden = YES;
        [_recordButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        [self checkFileExists];
        [self initPlayer];
        [self updateViewForPlayerInfo:_audioPlayer];
    }
}
- (IBAction)playAudio:(id)sender
{
    if (_audioPlayer.playing == YES)
		[self pausePlaybackForPlayer: _audioPlayer];
	else
		[self startPlaybackForPlayer: _audioPlayer];
}
- (IBAction)stopAudio:(id)sender
{
    _playButton.enabled = YES;
    _recordButton.enabled = YES;
    
    if (_audioRecorder.recording)
    {
        [_audioRecorder stop];
    } else if (_audioPlayer.playing) {
        [_audioPlayer stop];
    }
}


- (IBAction)discardAudio:(id)sender {
    
    if([self checkFileExists])
    {
        UIAlertView * fileExistsAlert = [[UIAlertView alloc] initWithTitle:@"Delete Audio" message:@"Are you sure you would like to delete the current audio?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
        fileExistsAlert.tag = 200;
        [fileExistsAlert show];
    }
    else
    {
        [self deletePreviousAudio];
    }
}

- (IBAction)progressSliderMoved:(UISlider *)sender
{
	_audioPlayer.currentTime = sender.value;
	[self updateCurrentTimeForPlayer:_audioPlayer];
}

- (IBAction)dismissPopover:(id)sender {
    [self stopAudio:nil];
    if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad){
        [[NSNotificationCenter defaultCenter] postNotificationName:@"testPop" object:nil];
    }
    else{
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark AudioSession handlers

void RouteChangeListener(	void *                  inClientData,
                         AudioSessionPropertyID	inID,
                         UInt32                  inDataSize,
                         const void *            inData)
{
	//avTouchController* This = (avTouchController*)inClientData;
	
	if (inID == kAudioSessionProperty_AudioRouteChange) {
		
		CFDictionaryRef routeDict = (CFDictionaryRef)inData;
		NSNumber* reasonValue = (NSNumber*)CFDictionaryGetValue(routeDict, CFSTR(kAudioSession_AudioRouteChangeKey_Reason));
		
		int reason = [reasonValue intValue];
        
		if (reason == kAudioSessionRouteChangeReason_OldDeviceUnavailable) {
            
			//[This pausePlaybackForPlayer:This.player];
		}
	}
}



#pragma mark AVAudioPlayer delegate methods
-(void)audioPlayerDidFinishPlaying:
(AVAudioPlayer *)player successfully:(BOOL)flag
{
    if (flag == NO)
		NSLog(@"Playback finished unsuccessfully");
    
	[player setCurrentTime:0.];
	if (_inBackground)
	{
		[self updateViewForPlayerStateInBackground:player];
	}
	else
	{
		[self updateViewForPlayerState:player];
	}
}

-(void)audioPlayerDecodeErrorDidOccur:
(AVAudioPlayer *)player error:(NSError *)error
{
    NSLog(@"Decode Error occurred");
}

-(void)audioRecorderDidFinishRecording:
(AVAudioRecorder *)recorder successfully:(BOOL)flag
{
    
}

-(void)audioRecorderEncodeErrorDidOccur:
(AVAudioRecorder *)recorder error:(NSError *)error
{
    NSLog(@"Encode Error occurred");
}

// we will only get these notifications if playback was interrupted
- (void)audioPlayerBeginInterruption:(AVAudioPlayer *)p
{
	NSLog(@"Interruption begin. Updating UI for new state");
	// the object has already been paused,	we just need to update UI
	if (_inBackground)
	{
		[self updateViewForPlayerStateInBackground:p];
	}
	else
	{
		[self updateViewForPlayerState:p];
	}
}

- (void)audioPlayerEndInterruption:(AVAudioPlayer *)p
{
	NSLog(@"Interruption ended. Resuming playback");
	[self startPlaybackForPlayer:p];
}

#pragma mark background notifications
- (void)registerForBackgroundNotifications
{
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(setInBackgroundFlag)
												 name:UIApplicationWillResignActiveNotification
											   object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(clearInBackgroundFlag)
												 name:UIApplicationWillEnterForegroundNotification
											   object:nil];
}

- (void)setInBackgroundFlag
{
	_inBackground = true;
}

- (void)clearInBackgroundFlag
{
	_inBackground = false;
}

#pragma mark - UIAlertView Delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(alertView.tag == 100)
    {
        switch (buttonIndex) {
                break;
            case 1:
                [self deletePreviousAudio];
                [self startRecording];
                break;
                
            default:
                break;
        }
    }
    else if(alertView.tag == 200)
    {
        switch (buttonIndex) {
                break;
            case 1:
                [self deletePreviousAudio];
                break;
                
            default:
                break;
        }
    }
}

@end
