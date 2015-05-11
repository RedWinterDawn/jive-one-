//
//  JCVoicemailDetailViewController.h
//  JiveOne
//
//  Created by P Leonard on 5/7/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JCVoicemailPlaybackCell.h"
#import "JCVoicemailCell.h"
#import "JCVoicemailAudioPlayer.h"
@import AVFoundation;
@import UIKit;

//@class JCVoicemailDetailViewPlayback;
//@protocol JCVoicemailDetailDelegate <NSObject>
//
//-(void)voiceDetailPlayTapped:(BOOL)play;
//-(void)sliderMoved:(float)value;
//-(void)sliderTouched:(BOOL)touched;
//-(void)voiceSpeakerTouched;
//-(void)voiceMailAudioAvailable:(BOOL)available;
//-(void)voiceDeleteTapped:(BOOL)deletePressed;
//
//@end

@interface JCVoicemailDetailViewController : UIViewController

//@property (nonatomic, weak) id <JCVoicemailDetailDelegate> delegate;

@property (strong, nonatomic) Voicemail *voicemail;

@property (nonatomic, weak) IBOutlet UILabel *duration;

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (nonatomic, weak) IBOutlet UIButton *playPauseButton;
@property (nonatomic, weak) IBOutlet UIButton *speakerButton;
@property (nonatomic, weak) IBOutlet UIButton *deleteButton;
@property (nonatomic, weak) IBOutlet JCPopoverSlider *slider;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *spinningWheel;

@property (nonatomic, strong) NSTimer *updateTimer;
@property (nonatomic, strong) NSIndexPath *indexPath;
@property (nonatomic) BOOL useSpeaker;

- (IBAction)playPauseButtonTapped:(id)sender;
- (IBAction)progressSliderMoved:(id)sender;
- (IBAction)progressSliderTouched:(id)sender;
- (IBAction)speakerTouched:(id)sender;

- (void)setSliderValue:(float)position;


@end
