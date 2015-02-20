//
//  JCMessagesViewController.h
//  JiveOne
//
//  Created by Robert Barclay on 2/2/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import <JCMessagesViewController/JSQMessagesViewController.h>

#import "JCMessagesInputToolbar.h"
#import "JCMessageParticipantTableViewController.h"

@interface JCConversationViewController : JSQMessagesViewController <JCMessageParticipantTableViewControllerDelegate>

@property (weak, nonatomic, readonly) UIButton *participantsButton;
@property (weak, nonatomic, readonly) JCMessagesInputToolbar *inputToolbar;

@property (strong, nonatomic) NSString *messageGroupId;


@end
