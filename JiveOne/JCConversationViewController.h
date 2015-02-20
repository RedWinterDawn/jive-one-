//
//  JCMessagesViewController.h
//  JiveOne
//
//  Created by Robert Barclay on 2/2/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import <JCMessagesViewController/JCMessagesViewController.h>

#import "JCConversationInputToolbar.h"
#import "JCMessageParticipantTableViewController.h"

@interface JCConversationViewController : JCMessagesViewController <JCMessageParticipantTableViewControllerDelegate>

@property (weak, nonatomic, readonly) UIButton *participantsButton;
@property (weak, nonatomic, readonly) JCConversationInputToolbar *inputToolbar;

@property (strong, nonatomic) NSString *messageGroupId;


@end
