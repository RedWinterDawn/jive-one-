//
//  JCConversationGroup.m
//  JiveOne
//
//  Created by Robert Barclay on 2/23/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCConversationGroup.h"

#import "Message.h"
#import "SMSMessage.h"
#import "LocalContact.h"

@implementation JCConversationGroup

-(instancetype)initWithConversationGroupId:(NSString *)conversationGroupId context:(NSManagedObjectContext *)context
{
    self = [super init];
    if (self) {
        _conversationGroupId = conversationGroupId;
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"messageGroupId = %@", conversationGroupId];
        Message *message = [Message MR_findFirstWithPredicate:predicate sortedBy:NSStringFromSelector(@selector(date)) ascending:NO inContext:context];
        if (message) {
            _lastMessage = message.text;
            _lastMessageReceived = message.date;
            _lastMessageId = message.eventId;
            NSString *name = _name;
            if (name) {
                _name = name;
            }
            else {
                
                if ([message isKindOfClass:[SMSMessage class]]) {
                    SMSMessage *smsMessage = (SMSMessage *)message;
                    _sms = TRUE;
                    _name = smsMessage.localContact.number;
                } else {
                    
                }
            }
        }
        [context refreshObject:message mergeChanges:NO];
    }
    return self;
}

-(BOOL)isEqual:(id)object
{
    if (![object isKindOfClass:[JCConversationGroup class]]) {
        return NO;
    }
    
    JCConversationGroup *conversationGroup = (JCConversationGroup *)object;
    if ([_conversationGroupId isEqual:conversationGroup.conversationGroupId]) {
        return YES;
    }
    return NO;
}

@end
