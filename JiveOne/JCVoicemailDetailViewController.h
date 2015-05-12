//
//  JCVoicemailDetailViewController.h
//  JiveOne
//
//  Created by P Leonard on 5/7/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import <StaticDataTableViewController/StaticDataTableViewController.h>

#import "Voicemail.h"
#import "JCPopoverSlider.h"

@interface JCVoicemailDetailViewController : StaticDataTableViewController

@property (strong, nonatomic) Voicemail *voicemail;

@property (weak, nonatomic) IBOutlet UILabel *duration;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIButton *playPauseButton;
@property (weak, nonatomic) IBOutlet UIButton *speakerButton;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;
@property (weak, nonatomic) IBOutlet JCPopoverSlider *slider;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinningWheel;

- (IBAction)playPauseButtonTapped:(id)sender;
- (IBAction)progressSliderMoved:(id)sender;
- (IBAction)progressSliderTouched:(id)sender;
- (IBAction)speakerTouched:(id)sender;

@end
