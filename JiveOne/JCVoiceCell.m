//
//  JCVoiceCell.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 4/17/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCVoiceCell.h"
#import "Common.h"

@implementation JCVoiceCell


- (void)awakeFromNib
{
    // Initialization code
}


- (void)setVoicemail:(Voicemail *)voicemail
{
    _voicemail = voicemail;

    //[self.userImage setImage:[UIImage imageNamed:@"avatar.png"]];
    
    if (voicemail.transcription) {
        self.titleLabel.text = voicemail.callerId;
        self.detailLabel.text = voicemail.transcription;
    }
    else {
        self.titleLabel.text = voicemail.callerId;
    }
    
    [self doubleCheckNamesAndNumbers];
    
    self.shortTime.text = [Common shortDateFromTimestamp:voicemail.timeStamp];
    self.creationTime.text = [Common longDateFromTimestamp:voicemail.timeStamp];
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
        self.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:16];
        self.detailLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:14];
        //self.voicemailIcon.image = [Common tintedImageWithColor:[UIColor redColor] image:self.voicemailIcon.image];
    }else{
//        self.shortTime.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14];
        self.creationTime.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14];
        self.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
        self.detailLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14];
        //self.voicemailIcon.image = [Common tintedImageWithColor:[UIColor blackColor] image:self.voicemailIcon.image];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:kVoicemailKeyPathForVoicemal]) {
        Voicemail *voicemail = (Voicemail *)object;
        
        if (voicemail && voicemail.jrn != nil && voicemail.url_self != nil) {
            _voicemail = voicemail;
            
            //[self performSelectorOnMainThread:@selector(setupAudioPlayer) withObject:nil waitUntilDone:NO];
            [self.spinningWheel performSelectorOnMainThread:@selector(stopAnimating) withObject:nil waitUntilDone:NO];
            if (_delegate) {
                [_delegate voiceCellAudioAvailable:_indexPath];
            }
        }
    }
}

- (void)doubleCheckNamesAndNumbers
{
    if ([Common stringIsNilOrEmpty:self.titleLabel.text] || [self.titleLabel.text isEqualToString:@"Unknown"]) {
        NSString *regexForName = @"\".+?\"";
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexForName
                                                                               options:NSRegularExpressionCaseInsensitive
                                                                                 error:nil];
        if ([Common stringIsNilOrEmpty:_voicemail.callerId]) {
            return;
        }
        NSArray *matches = [regex matchesInString:_voicemail.callerId
                                          options:0
                                            range:NSMakeRange(0, [_voicemail.callerId length])];
        
        if (matches.count > 0) {
            NSString *callerName = [_voicemail.callerId substringWithRange:[matches[0] range]];
            callerName = [callerName stringByReplacingOccurrencesOfString:@"\"" withString:@""];
            self.titleLabel.text = callerName;
        }
    }
    
    if ([Common stringIsNilOrEmpty:self.detailLabel.text] || [self.detailLabel.text isEqualToString:@"Unknown"]) {
        NSString *regexForNumber = @"<.+?>";
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexForNumber
                                                          options:NSRegularExpressionCaseInsensitive
                                                            error:nil];
        NSArray *matches = [regex matchesInString:_voicemail.callerId
                                 options:0
                                   range:NSMakeRange(0, [_voicemail.callerId length])];
        
        if (matches.count > 0) {
            NSString *callerNumber = [_voicemail.callerId substringWithRange:[matches[0] range]];
            callerNumber = [callerNumber stringByReplacingOccurrencesOfString:@"<" withString:@""];
            callerNumber = [callerNumber stringByReplacingOccurrencesOfString:@">" withString:@""];
            self.detailLabel.text = callerNumber;
        }
    }
}

-(void)prepareForReuse
{
    [super prepareForReuse];
    [self removeObservers];
}

-(void)removeObservers
{
    if (_voicemail)
        [_voicemail removeObserver:self forKeyPath:kVoicemailKeyPathForVoicemal];
}

- (IBAction)playPauseButtonTapped:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(voiceCellPlayTapped:)]) {
        [self.delegate voiceCellPlayTapped:self];
    }
}

- (IBAction)progressSliderMoved:(id)sender {
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

- (IBAction)speakerTouched:(id)sender;
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(voicecellSpeakerTouched:)]) {
        [self.delegate voicecellSpeakerTouched:YES];
    }
}

-(IBAction)voiceCellDeleteTapped:(NSIndexPath *)indexPath
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(voiceCellDeleteTapped:)]) {
        [self.delegate voiceCellDeleteTapped:indexPath];
    }
}

- (void)setSpeakerButtonTint:(UIColor*)color
{
    [_speakerButton.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    _speakerButton.imageView.image = [Common tintedImageWithColor:color image:_speakerButton.imageView.image];
}

@end
