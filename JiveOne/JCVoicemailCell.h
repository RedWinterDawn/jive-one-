//
//  JCVoiceMailCell.h
//  Jive
//
//  Created by Doug Leonard on 4/18/14.
//  Copyright (c) 2013 Jive Communications. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "Voicemail.h"

@class JCVoicemailCell;
@protocol JCVoicemailCellDelegate <NSObject>
-(void)voiceCellToggleTapped:(JCVoicemailCell *)cell;
-(void)voiceCellPlayTapped:(JCVoicemailCell *)cell;
-(void)voiceCellInfoTapped:(JCVoicemailCell *)cell;
-(void)voiceCellReplyTapped:(JCVoicemailCell *)cell;
-(void)voiceCellDeleteTapped:(JCVoicemailCell *)cell;
-(void)voiceCellSpeakerTapped:(JCVoicemailCell *)cell;
- (void)sliderValueChanged:(JCVoicemailCell *)cell;
@end

@interface JCVoicemailCell : UITableViewCell <AVAudioPlayerDelegate>
@property (weak, nonatomic) IBOutlet UILabel *callerId;
@property (weak, nonatomic) IBOutlet UILabel *phone_state;
@property (weak,nonatomic) IBOutlet UIButton *playButton;
@property (weak,nonatomic) IBOutlet UILabel  *creationTime;
@property (weak,nonatomic) IBOutlet UILabel  *elapsed;
@property (weak,nonatomic) IBOutlet UILabel  *duration;
@property (weak,nonatomic) IBOutlet UILabel  *shortTime;
@property (weak,nonatomic) IBOutlet UIButton *speakerButton;
@property (weak,nonatomic) IBOutlet UISlider *slider;
@property (weak, nonatomic) IBOutlet UIImageView *userImage;
@property (weak, nonatomic) IBOutlet UIImageView *voicemailIcon;
@property (nonatomic) BOOL useSpeaker;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *spinningWheel;

@property (weak,nonatomic) Voicemail *voicemailObject;
-(Voicemail*)getVoicemailObject;
@property (weak,nonatomic) id<JCVoicemailCellDelegate> delegate;

#pragma mark - Methods
+(NSString *)reuseIdentifier;
+(CGFloat)cellHeightForData:(id)data selected:(BOOL)selected;
-(void)configureWithItem:(Voicemail *)item andDelegate:(id)delegate;
-(void)pause;
-(void)stop;
-(void)play;
-(void)playAtTime:(NSInteger) time;
-(BOOL)isPlaying;

#pragma mark - Actions
-(IBAction)playTapped:(id)sender;
-(IBAction)infoTapped:(id)sender;
-(IBAction)deleteTapped:(id)sender;
-(IBAction)replyTapped:(id)sender;
-(IBAction)speakerTapped:(id)sender;
-(IBAction)progressSliderMoved:(UISlider*)sender;
@end
