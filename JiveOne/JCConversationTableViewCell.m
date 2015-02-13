//
//  JCConversationTableViewCell.m
//  JiveOne
//
//  Created by Robert Barclay on 2/13/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCConversationTableViewCell.h"
#import "Message.h"
#import "SMSMessage.h"
#import "LocalContact.h"

@implementation JCConversationTableViewCell

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"messageGroupId = %@", _messageGroupId];
    Message *message = [Message MR_findFirstWithPredicate:predicate sortedBy:@"date" ascending:NO];
    if ([message isKindOfClass:[SMSMessage class]]) {
        SMSMessage *smsMessage = (SMSMessage *)message;
        self.senderNameLabel.text = smsMessage.localContact.name;
    }
    
    self.lastMessageLabel.text = message.text;
    self.dateLabel.text = message.formattedModifiedShortDate;
    [message.managedObjectContext refreshObject:message mergeChanges:NO];
}

@end
