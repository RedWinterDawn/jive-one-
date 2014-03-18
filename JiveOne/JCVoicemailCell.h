//
//  JCVoiceMailCell.h
//  Jive
//
//  Created by Doug Leonard on 4/18/14.
//  Copyright (c) 2013 Jive Communications. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import "JCRecentItemCellProtocol.h"
#import <AVFoundation/AVFoundation.h>
#import "Voicemail.h"

@class JCVoicemailCell;
@protocol JCVoicemailCellDelegate <NSObject>
-(void)voiceCellToggleTapped:(JCVoicemailCell *)cell;
-(void)voiceCellPlayTapped:(JCVoicemailCell *)cell;
-(void)voiceCellInfoTapped:(JCVoicemailCell *)cell;
-(void)voiceCellReplyTapped:(JCVoicemailCell *)cell;
-(void)voiceCellArchiveTapped:(JCVoicemailCell *)cell;
-(void)voiceCellSpeakerTapped:(JCVoicemailCell *)cell;
@end

@interface JCVoicemailCell : UITableViewCell <AVAudioPlayerDelegate>
@property (weak,nonatomic) IBOutlet UIButton *playButton;
@property (weak,nonatomic) IBOutlet UIButton *replyButton;
@property (weak,nonatomic) IBOutlet UILabel  *creationTime;
@property (weak,nonatomic) IBOutlet UILabel  *elapsed;
@property (weak,nonatomic) IBOutlet UILabel  *duration;
@property (weak,nonatomic) IBOutlet UIButton *infoButton;
@property (weak,nonatomic) IBOutlet UIButton *archiveButton;
@property (weak,nonatomic) IBOutlet UIProgressView *progressView;
@property (weak,nonatomic) IBOutlet UILabel  *username;
@property (weak,nonatomic) IBOutlet UIButton *speakerButton;
@property (weak,nonatomic) IBOutlet UIButton *expandToggleButton;
@property (nonatomic) BOOL useSpeaker;

@property (weak,nonatomic) Voicemail *voicemailObject;
@property (weak,nonatomic) id<JCVoicemailCellDelegate> delegate;

#pragma mark - Methods
+(CGFloat)cellHeightForData:(id)data selected:(BOOL)selected;
-(void)configureWithItem:(Voicemail *)item andDelegate:(id)delegate;
-(void)pause;
-(void)stop;
-(void)play;
-(BOOL)isPlaying;

#pragma mark - Actions
-(IBAction)toggleTapped:(id)sender;
-(IBAction)playTapped:(id)sender;
-(IBAction)infoTapped:(id)sender;
-(IBAction)archiveTapped:(id)sender;
-(IBAction)replyTapped:(id)sender;
-(IBAction)speakerTapped:(id)sender;
@end
