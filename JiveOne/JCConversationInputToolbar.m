//
//  JCMessagesInputToolbar.m
//  JiveOne
//
//  Created by Robert Barclay on 2/2/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCConversationInputToolbar.h"
#import <JCMessagesViewController/UIView+JSQMessages.h>
#import <JCMessagesViewController/JSQMessagesToolbarButtonFactory.h>

@interface JCConversationInputToolbar ()

@end

@implementation JCConversationInputToolbar

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.contentView.leftBarButtonItem = nil;
    self.contentView.rightBarButtonItem = [JSQMessagesToolbarButtonFactory defaultSendButtonItem];
}

@end
