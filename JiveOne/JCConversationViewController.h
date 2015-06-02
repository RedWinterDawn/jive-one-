//
//  JCMessagesViewController.h
//  JiveOne
//
//  Created by Robert Barclay on 2/2/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import <JCMessagesViewController/JCMessagesViewController.h>
#import "JCMessageParticipantTableViewController.h"

@interface JCConversationViewController : JCMessagesViewController <JCMessageParticipantTableViewControllerDelegate, UIActionSheetDelegate>

@property (weak, nonatomic, readonly) UIButton *participantsButton;
@property (strong, nonatomic) NSString *messageGroupId;

@end
