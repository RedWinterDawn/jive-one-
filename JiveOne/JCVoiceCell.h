//
//  JCVoiceCell.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 4/17/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Voicemail+Custom.h"
#import "JCPopoverSlider.h"
#import "JCSpeakerView.h"
#import "JCPlayPauseButton.h"

@class JCVoiceCell;
@protocol JCVoiceCellDelegate <NSObject>
- (void)voiceCellPlayTapped:(JCVoiceCell *)cell;
- (void)voiceCellSliderMoved:(float)value;
- (void)voiceCellSliderTouched:(BOOL)touched;
- (void)voicecellSpeakerTouched:(BOOL)touched;
- (void)voiceCellAudioAvailable:(NSIndexPath *)indexPath;
- (void)voiceCellDeleteTapped:(NSIndexPath *)indexPath;
@end

@interface JCVoiceCell : UITableViewCell


@property (strong, nonatomic) Voicemail *voicemail;
@property (weak,nonatomic) id<JCVoiceCellDelegate> delegate;
#pragma mark - Visible Collapsed

@property (weak, nonatomic) IBOutlet UILabel *callerIdLabel;
@property (weak, nonatomic) IBOutlet UILabel *callerNumberLabel;
@property (weak, nonatomic) IBOutlet UILabel *extensionLabel;
//@property (weak,nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet JCPlayPauseButton *playPauseButton;
@property (weak,nonatomic) IBOutlet UILabel  *creationTime;
@property (weak,nonatomic) IBOutlet UILabel  *elapsed;
@property (weak,nonatomic) IBOutlet UILabel  *duration;
@property (weak,nonatomic) IBOutlet UILabel  *shortTime;
@property (weak, nonatomic) IBOutlet JCSpeakerView *speakerView;
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
