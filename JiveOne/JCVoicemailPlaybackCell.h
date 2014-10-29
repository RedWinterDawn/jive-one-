//
//  JCVoiceCell.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 4/17/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCVoicemailCell.h"

#import "Voicemail+Custom.h"
#import "JCPopoverSlider.h"
#import "JCSpeakerButton.h"
#import "JCPlayPauseButton.h"

@class JCVoicemailPlaybackCell;
@protocol JCVoiceCellDelegate <NSObject>
- (void)voiceCellPlayTapped:(JCVoicemailPlaybackCell *)cell;
- (void)voiceCellSliderMoved:(float)value;
- (void)voiceCellSliderTouched:(BOOL)touched;
- (void)voicecellSpeakerTouched;
- (void)voiceCellAudioAvailable:(NSIndexPath *)indexPath;
- (void)voiceCellDeleteTapped:(JCVoicemailPlaybackCell *)cell;
@end

@interface JCVoicemailPlaybackCell : JCVoicemailCell


@property (weak,nonatomic) id<JCVoiceCellDelegate> delegate;
#pragma mark - Visible Collapsed


@property (weak, nonatomic) IBOutlet UIButton *playPauseButton;
@property (weak,nonatomic) IBOutlet UILabel  *elapsed;
@property (weak,nonatomic) IBOutlet UILabel  *shortTime;
@property (weak,nonatomic) IBOutlet UIButton *speakerButton;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;

@property (weak,nonatomic) IBOutlet JCPopoverSlider *slider;
@property (weak, nonatomic) IBOutlet UIImageView *userImage;
@property (weak, nonatomic) IBOutlet UIImageView *voicemailIcon;
@property (nonatomic, retain)	NSTimer			*updateTimer;
@property (nonatomic) BOOL useSpeaker;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *spinningWheel;
@property (strong, nonatomic) NSIndexPath *indexPath;

- (IBAction)playPauseButtonTapped:(id)sender;
//- (void)setPlayButtonState:(UIImage *)image;
- (IBAction)progressSliderMoved:(id)sender;
- (IBAction)progressSliderTouched:(id)sender;
- (IBAction)speakerTouched:(id)sender;
- (void)setSliderValue:(float)position;
- (void)styleCellForRead;
//- (void)setupButtons;
@end
