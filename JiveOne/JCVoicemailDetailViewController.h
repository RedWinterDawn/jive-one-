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

@interface JCVoicemailDetailViewController : UIViewController

@property (strong, nonatomic) Voicemail *voicemail;

@property (weak, nonatomic) IBOutlet UILabel *duration;
@property (weak, nonatomic) IBOutlet UILabel *name;
@property (weak, nonatomic) IBOutlet UILabel *date;
@property (weak, nonatomic) IBOutlet UILabel *number;

@property (weak, nonatomic) IBOutlet UIButton *playPauseButton;
@property (weak, nonatomic) IBOutlet UIButton *speakerButton;
@property (weak, nonatomic) IBOutlet UISlider *slider;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinningWheel;

- (IBAction)playPauseButtonTapped:(id)sender;
- (IBAction)progressSliderMoved:(id)sender;
- (IBAction)progressSliderTouched:(id)sender;
- (IBAction)speakerTouched:(id)sender;
- (IBAction)deleteVoicemail:(id)sender;

@end
