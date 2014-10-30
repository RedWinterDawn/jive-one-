//
//  JCVoiceCell.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 4/17/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCVoicemailPlaybackCell.h"
#import "Common.h"
#import "PBX+Custom.h"
#import "Lines+Custom.h"

@implementation JCVoicemailPlaybackCell


- (void)awakeFromNib
{
    // Initialization code
}


- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.shortTime.text = self.voicemail.formattedModifiedShortDate;
    self.creationTime.text = self.voicemail.formattedModifiedShortDate;
    self.elapsed.text = @"0:00";
    self.duration.text = @"0:00";
    self.elapsed.adjustsFontSizeToFitWidth = YES;
    self.duration.adjustsFontSizeToFitWidth = YES;
    self.slider.minimumValue = 0.0;
    
    //test to see if we have already downloaded the voicemail .wav file
    if (self.voicemail.voicemail.length > 0) {
        // if the activityIndicator is visible
        if (![self.spinningWheel isHidden]) {
            [self.spinningWheel performSelectorOnMainThread:@selector(stopAnimating) withObject:nil waitUntilDone:NO];
            //stopAnimating should also hide the activity indicator
        }
    }
    
    [self.voicemail addObserver:self forKeyPath:kVoicemailKeyPathForVoicemal options:NSKeyValueObservingOptionNew context:NULL];
    
    [self styleCellForRead];
}

- (void)styleCellForRead
{
    [_voicemailIcon.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    if(![self.voicemail.read boolValue]){
//        self.shortTime.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14];
        self.creationTime.font = [UIFont fontWithName:@"HelveticaNeue" size:14];
        self.callerIdLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:16];
        self.extensionLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:14];
        //self.voicemailIcon.image = [Common tintedImageWithColor:[UIColor redColor] image:self.voicemailIcon.image];
    }else{
//        self.shortTime.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14];
        self.creationTime.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14];
        self.callerIdLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
        self.extensionLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14];
        //self.voicemailIcon.image = [Common tintedImageWithColor:[UIColor blackColor] image:self.voicemailIcon.image];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:kVoicemailKeyPathForVoicemal]) {
        Voicemail *voicemail = (Voicemail *)object;
        
        if (voicemail && voicemail.jrn != nil && voicemail.url_self != nil) {
            self.voicemail = voicemail;
            
            //[self performSelectorOnMainThread:@selector(setupAudioPlayer) withObject:nil waitUntilDone:NO];
            [self.spinningWheel performSelectorOnMainThread:@selector(stopAnimating) withObject:nil waitUntilDone:NO];
            if (_delegate) {
                [_delegate voiceCellAudioAvailable:_indexPath];
            }
        }
    }
}



-(void)prepareForReuse
{
    [super prepareForReuse];
    [self removeObservers];
    
    
    self.playPauseButton.selected = false;
    self.speakerButton.selected = false;
}

-(void)removeObservers
{
    if (self.voicemail)
        [self.voicemail removeObserver:self forKeyPath:kVoicemailKeyPathForVoicemal];
}

- (IBAction)playPauseButtonTapped:(id)sender
{
    if ([sender isKindOfClass:[UIButton class]]) {
        UIButton *button = (UIButton *)sender;
        button.selected = !button.selected;
        if (self.delegate && [self.delegate respondsToSelector:@selector(voiceCellPlayTapped:)]) {
            [self.delegate voiceCellPlayTapped:self];
        }
    }
}

#pragma mark - IBActions -


- (IBAction)progressSliderMoved:(id)sender
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(voiceCellSliderMoved:)]) {
        [self.delegate voiceCellSliderMoved:self.slider.value];
    }
}

- (void)setSliderValue:(float)value
{
    self.slider.value = value;
}

- (IBAction)progressSliderTouched:(id)sender
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(voiceCellSliderTouched:)]) {
        [self.delegate voiceCellSliderTouched:YES];
    }
}

- (IBAction)speakerTouched:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(voicecellSpeakerTouched)]) {
        [self.delegate voicecellSpeakerTouched];
    }
}

-(IBAction)voiceCellDeleteTapped:(id)sender
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(voiceCellDeleteTapped:)]) {
        [self.delegate voiceCellDeleteTapped:self];
    }
}

@end
