//
//  JCVoiceCell.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 4/17/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCVoicemailCell.h"

#import "Voicemail+V5Client.h"
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

@property (nonatomic, weak) id <JCVoiceCellDelegate> delegate;
@property (nonatomic, strong) Voicemail *voicemail;

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
