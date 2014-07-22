//
//  JCVoiceTableViewController.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 4/17/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "JCVoiceCell.h"
#import "JCVoicemailClient.h"

@interface JCVoiceTableViewController : UITableViewController <AVAudioPlayerDelegate, JCVoiceCellDelegate>

@property (nonatomic) NSMutableArray *voicemails; // exposed for testing
@property (nonatomic) JCVoiceCell *selectedCell;//exposed for testing
- (void)updateVoiceTable:(id)sender;
- (void)loadVoicemails;
- (void)setClient:(JCVoicemailClient*)client;
- (void)voiceCellPlayTapped:(JCVoiceCell *)cell; //exposed for testing
- (void)voiceCellDeleteTapped:(NSIndexPath *)indexPath;
- (void)addOrRemoveSelectedIndexPath:(NSIndexPath *)indexPath;
@end
