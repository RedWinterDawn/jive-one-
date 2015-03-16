//
//  JCVoiceCell.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 4/17/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCVoicemailPlaybackCell.h"
#import "Common.h"

@implementation JCVoicemailPlaybackCell

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.slider.minimumValue = 0.0;
    
    // Loading indicator.
    [self.voicemail addObserver:self forKeyPath:kVoicemailDataAttributeKey options:NSKeyValueObservingOptionNew context:NULL];
    if (self.voicemail.data.length > 0) {
        [self.spinningWheel stopAnimating];
        self.playPauseButton.enabled = true;
    }
    else {
        [self.spinningWheel startAnimating];
        self.playPauseButton.enabled = false;
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:kVoicemailDataAttributeKey]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.spinningWheel stopAnimating];
            if (_delegate) {
                [_delegate voiceCellAudioAvailable:_indexPath];
            }
        });
    }
    else
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

-(void)prepareForReuse
{
    [super prepareForReuse];

    if (self.voicemail){
        [self.voicemail removeObserver:self forKeyPath:kVoicemailDataAttributeKey];
    }
    
    self.playPauseButton.selected = false;
    self.speakerButton.selected = false;
}

-(void)dealloc
{
    if (self.voicemail){
        [self.voicemail removeObserver:self forKeyPath:kVoicemailDataAttributeKey];
    }
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

@end
