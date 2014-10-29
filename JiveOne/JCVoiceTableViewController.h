//
//  JCVoiceTableViewController.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 4/17/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "JCVoicemailPlaybackCell.h"
#import "JCVoicemailClient.h"
#import "JCRecentActivityTableViewController.h"

@interface JCVoiceTableViewController : JCRecentActivityTableViewController <AVAudioPlayerDelegate, JCVoiceCellDelegate>

//@property (nonatomic) NSMutableArray *voicemails; // exposed for testing
@property (nonatomic) JCVoicemailPlaybackCell *selectedCell;//exposed for testing


- (void)updateVoiceTable:(id)sender;
- (void)setClient:(JCVoicemailClient*)client;
- (void)voiceCellPlayTapped:(JCVoicemailPlaybackCell *)cell; //exposed for testing
- (void)voiceCellDeleteTapped:(NSIndexPath *)indexPath;
- (void)addOrRemoveSelectedIndexPath:(NSIndexPath *)indexPath;
@end
