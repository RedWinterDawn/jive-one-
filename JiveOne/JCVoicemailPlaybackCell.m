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

- (void)layoutSubviews
{
    [super layoutSubviews];
    
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

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:kVoicemailKeyPathForVoicemal]) {
        Voicemail *voicemail = (Voicemail *)object;
        if (voicemail && voicemail.jrn != nil && voicemail.url_self != nil) {
            self.voicemail = voicemail;
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

#pragma mark - Methods -

- (void)setSliderValue:(float)value
{
    self.slider.value = value;
}

#pragma mark - IBActions -

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

- (IBAction)progressSliderMoved:(id)sender
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(voiceCellSliderMoved:)]) {
        [self.delegate voiceCellSliderMoved:self.slider.value];
    }
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

#pragma mark - Private -

- (void)styleCellForRead
{
    if(!self.voicemail.read){
        self.date.font = [UIFont fontWithName:@"HelveticaNeue" size:14];
        self.name.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:16];
        self.extension.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:14];
    }else{
        self.date.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14];
        self.name.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
        self.extension.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14];
    }
}

-(void)removeObservers
{
    if (self.voicemail)
        [self.voicemail removeObserver:self forKeyPath:kVoicemailKeyPathForVoicemal];
}

@end
