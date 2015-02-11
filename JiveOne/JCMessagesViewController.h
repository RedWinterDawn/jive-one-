//
//  JCMessagesViewController.h
//  JiveOne
//
//  Created by Robert Barclay on 2/2/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import <JSQMessagesViewController/JSQMessagesViewController.h>

#import "JCMessagesInputToolbar.h"

@interface JCMessagesViewController : JSQMessagesViewController

@property (weak, nonatomic, readonly) UIButton *participantsButton;
@property (weak, nonatomic, readonly) JCMessagesInputToolbar *inputToolbar;

@property (strong, nonatomic) NSString *conversationId;
@property (strong, nonatomic) NSString *senderNumber;

@end
