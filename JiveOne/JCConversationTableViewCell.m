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
#import "JCAddressBook.h"

@implementation JCConversationTableViewCell

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"messageGroupId = %@", _messageGroupId];
    Message *message = [Message MR_findFirstWithPredicate:predicate sortedBy:@"date" ascending:NO];
    if ([message isKindOfClass:[SMSMessage class]]) {
        SMSMessage *smsMessage = (SMSMessage *)message;
        NSString *name = smsMessage.localContact.name;
        if (name) {
            self.senderNameLabel.text = name;
        } else {
//            [JCAddressBook formattedNameForNumber:smsMessage.localContact.number completion:^(NSString *name, NSError *error) {
//                self.senderNameLabel.text = name;
//            }];
        }
    }
    
    self.lastMessageLabel.text = message.text;
    self.dateLabel.text = message.formattedModifiedShortDate;
    [message.managedObjectContext refreshObject:message mergeChanges:NO];
}

@end
