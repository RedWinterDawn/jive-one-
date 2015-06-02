//
//  JCVoicemailDetailViewController.h
//  JiveOne
// 
//  Created by P Leonard on 5/7/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

@import UIKit;

#import "Voicemail.h"
#import "JCPopoverSlider.h"
#import "JCPlayPauseButton.h"

@protocol JCVoicemailDetailViewControllerDelegate;

@interface JCVoicemailDetailViewController : UIViewController

@property (strong, nonatomic) Voicemail *voicemail;

@property (weak, nonatomic) id <JCVoicemailDetailViewControllerDelegate> delegate;

@property (weak, nonatomic) IBOutlet UILabel *duration;
@property (weak, nonatomic) IBOutlet UILabel *name;
@property (weak, nonatomic) IBOutlet UILabel *date;
@property (weak, nonatomic) IBOutlet UILabel *number;
@property (weak, nonatomic) IBOutlet UILabel *transcriptionWordCount;
@property (weak, nonatomic) IBOutlet UILabel *transcriptionConfidence;
@property (weak, nonatomic) IBOutlet UITextView *voicemailTranscription;

@property (weak, nonatomic) IBOutlet JCPlayPauseButton *playPauseButton;
@property (weak, nonatomic) IBOutlet UIButton *speakerButton;
@property (weak, nonatomic) IBOutlet JCPopoverSlider *slider;
@property (weak, nonatomic) IBOutlet UILabel *playerDuration;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;

- (IBAction)playPauseButtonTapped:(id)sender;
- (IBAction)progressSliderMoved:(id)sender;
- (IBAction)speakerTouched:(id)sender;
- (IBAction)deleteVoicemail:(id)sender;

@end


@protocol JCVoicemailDetailViewControllerDelegate <NSObject>

-(void)voicemailDetailViewControllerDidDeleteVoicemail:(JCVoicemailDetailViewController *)controller;

@end