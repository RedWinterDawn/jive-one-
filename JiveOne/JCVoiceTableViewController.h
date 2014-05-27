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
#import "JCOsgiClient.h"

@interface JCVoiceTableViewController : UITableViewController <AVAudioPlayerDelegate, JCVoiceCellDelegate>

@property (nonatomic) NSMutableArray *voicemails; // exposed for testing
- (void)updateTable;
- (void)loadVoicemails;
- (void)osgiClient:(JCOsgiClient*)client;
- (void)voiceCellDeleteTapped:(NSIndexPath *)indexPath;
- (void)addOrRemoveSelectedIndexPath:(NSIndexPath *)indexPath;
@end
