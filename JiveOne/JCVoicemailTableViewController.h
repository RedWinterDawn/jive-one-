//
//  JCVoiceTableViewController.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 4/17/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCRecentLineEventsTableViewController.h"
#import "JCVoicemailPlaybackCell.h"

@interface JCVoicemailTableViewController : JCRecentLineEventsTableViewController

@property (nonatomic) JCVoicemailPlaybackCell *selectedCell; //exposed for testing

- (void)voiceCellPlayTapped:(JCVoicemailPlaybackCell *)cell; //exposed for testing

@end
