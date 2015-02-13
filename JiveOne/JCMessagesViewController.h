//
//  JCMessagesViewController.h
//  JiveOne
//
//  Created by Robert Barclay on 2/2/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import <JSQMessagesViewController/JSQMessagesViewController.h>

#import "JCMessagesInputToolbar.h"
#import "JCMessageParticipantTableViewController.h"

@interface JCMessagesViewController : JSQMessagesViewController <JCMessageParticipantTableViewControllerDelegate>

@property (weak, nonatomic, readonly) UIButton *participantsButton;
@property (weak, nonatomic, readonly) JCMessagesInputToolbar *inputToolbar;

@property (strong, nonatomic) NSString *messageGroupId;
@property (strong, nonatomic) NSString *senderNumber;

@end
