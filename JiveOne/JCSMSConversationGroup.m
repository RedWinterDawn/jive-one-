//
//  JCSMSConversationGroup.m
//  JiveOne
//
//  Created by Robert Barclay on 4/28/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCSMSConversationGroup.h"
#import "LocalContact.h"
#import "JCUnknownNumber.h"
#import "Common.h"

@implementation JCSMSConversationGroup

@synthesize sms           = _sms;
@synthesize read          = _read;
@synthesize lastMessage   = _lastMessage;
@synthesize lastMessageId = _lastMessageId;
@synthesize date          = _date;

-(instancetype)initWithName:(SMSMessage *)smsMessage phoneNumber:(id<JCPhoneNumberDataSource>)phoneNumber
{
    self = [super initWithName:phoneNumber.name number:smsMessage.messageGroupId];
    if (self) {
        _sms = TRUE;
        _read           = [self readStateForConversationGroupId:smsMessage.messageGroupId context:smsMessage.managedObjectContext];
        _lastMessageId  = smsMessage.eventId;
        _lastMessage    = smsMessage.text;
        _date           = smsMessage.date;
    }
    return self;
}

-(BOOL)readStateForConversationGroupId:(NSString *)conversationGroupId context:(NSManagedObjectContext *)context
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"messageGroupId = %@", conversationGroupId];
    NSArray *messages = [Message MR_findAllWithPredicate:predicate inContext:context];
    for (Message *message in messages) {
        if (!message.isRead) {
            return FALSE;
        }
    }
    return TRUE;
}

-(NSString *)titleText
{
    NSString *name = self.name;
    if (name) {
        return name;
    }
    return self.formattedNumber;
}

-(NSString *)detailText
{
    return self.lastMessage;
}

-(NSString *)formattedModifiedShortDate
{
    return [Common formattedModifiedShortDate:self.date];
}

-(NSString *)conversationGroupId
{
    return self.number;
}

@end
