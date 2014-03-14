//
//  AudioRecordingViewController.h
//  CRNAUA2
//
//  Created by Eduardo Gueiros on 11/13/13.
//  Copyright (c) All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@protocol AudioRecordingDismissDelegate <NSObject>

-(void)dismissPopover;

@end

@interface AudioRecordingViewController : UIViewController <AVAudioRecorderDelegate, AVAudioPlayerDelegate, UIAlertViewDelegate, UIPopoverControllerDelegate>

@property (strong, nonatomic) AVAudioRecorder *audioRecorder;
@property (strong, nonatomic) AVAudioPlayer *audioPlayer;
@property (strong, nonatomic) IBOutlet UIButton *recordButton;
@property (strong, nonatomic) IBOutlet UIButton *playButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *discardButton;
@property (strong, nonatomic) IBOutlet UISlider *progressSlider;
@property (strong, nonatomic) IBOutlet UIButton *stopButton;
@property (strong, nonatomic) IBOutlet UILabel *currentTime;
@property (strong, nonatomic) IBOutlet UILabel *durationTime;
@property (nonatomic, retain)	NSTimer			*updateTimer;
@property (nonatomic, assign)	BOOL			inBackground;
@property (strong, nonatomic) IBOutlet UIView *recordingView;
@property (assign, nonatomic) id<AudioRecordingDismissDelegate> delegate;

- (IBAction)recordAudio:(id)sender;
- (IBAction)playAudio:(id)sender;
- (IBAction)stopAudio:(id)sender;
- (IBAction)discardAudio:(id)sender;
- (IBAction)progressSliderMoved:(UISlider*)sender;
- (IBAction)dismissPopover:(id)sender;

- (void) registerForBackgroundNotifications;
@end
