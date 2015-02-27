//
//  JCMessagesMenuCell.m
//  JiveOne
//
//  Created by P Leonard on 2/26/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCMessagesMenuCell.h"
#import "JCBadgeManager.h"

@interface JCMessagesMenuCell (){
    JCBadgeViewStyle *_unreadSMSDefaultStyle;
     JCBadgeViewStyle *_unreadSMSDisabledStyle;
     JCBadgeViewStyle *_unreadChatDefaultStyle;
     JCBadgeViewStyle *_unreadChatDisabledStyle;
}

@end

@implementation JCMessagesMenuCell

-(void)awakeFromNib
{
    JCBadgeManager *badgeManager = [JCBadgeManager sharedManager];
    [badgeManager addObserver:self forKeyPath:@"smsMessages" options:NSKeyValueObservingOptionNew context:NULL];
//observe chat when that is a thing
//    [badgeManager addObserver:self forKeyPath:@"chatMessages" options:NSKeyValueObservingOptionNew context:NULL];
    
    _unreadSMSDefaultStyle = self.unreadSMSMessagesView.badgeStyle;
//    _unreadChatDefaultStyle = self.unreadChatMessagesView.badgeStyle;
    
    _unreadSMSDisabledStyle = [_unreadSMSDefaultStyle copy];
    _unreadSMSDisabledStyle.badgeInsetColor = [UIColor lightGrayColor];
    
  //  _unreadChatDisabledStyle = [_unreadSMSDefaultStyle copy];
 //   _unreadChatDisabledStyle.badgeInsetColor = _unreadChatDefaultStyle.badgeInsetColor;
}

-(void)dealloc {
    JCBadgeManager *badgeManager = [JCBadgeManager sharedManager];
    [badgeManager removeObserver:self forKeyPath:@"smsMessages"];
//    [badgeManager removeObserver:self forKeyPath:@"chatMessages"];
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    JCBadgeManager *badgeManager = [JCBadgeManager sharedManager];
    
    // Unread SMS
    NSUInteger smsMessages = badgeManager.smsMessages;
    if (smsMessages > 0) {
        self.unreadSMSMessagesView.badgeStyle = _unreadSMSDefaultStyle;
    }
    else {
        self.unreadSMSMessagesView.badgeStyle = _unreadSMSDisabledStyle;
    }
    self.unreadSMSMessagesView.badgeText = [NSString stringWithFormat:@"%lu", (unsigned long)smsMessages];
    
    // Unread Chat
//    NSUInteger chatMessages = badgeManager.chatMessages;
//    if (chatMessages > 0) {
//        self.unreadChatMessagesView.badgeStyle = _unreadChatDefaultStyle;
//    }
//    else {
//        self.unreadChatMessagesView.badgeStyle = _unreadChatDefaultStyle;
//    }
//    self.unreadChatMessagesView.badgeText = [NSString stringWithFormat:@"%lu", (unsigned long)chatMessages];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"smsMessages"] /*|| [keyPath isEqualToString:@"missedCalls"]*/) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setNeedsLayout];
            [self setNeedsUpdateConstraints];
        });
    }
}

@end
