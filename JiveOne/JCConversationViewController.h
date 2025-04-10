//
//  JCMessagesViewController.h
//  JiveOne
//
//  Created by Robert Barclay on 2/2/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import <JCMessagesViewController/JCMessagesViewController.h>
#import "JCMessageParticipantTableViewController.h"
#import "JCMessageGroup.h"

@interface JCConversationViewController : JCMessagesViewController <JCMessageParticipantTableViewControllerDelegate, UIActionSheetDelegate>

@property (weak, nonatomic, readonly) UIButton *participantsButton;
@property (nonatomic, strong) JCMessageGroup *messageGroup;

@end


