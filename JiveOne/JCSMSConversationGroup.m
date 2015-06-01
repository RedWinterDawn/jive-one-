//
//  JCSMSConversationGroup.m
//  JiveOne
//
//  Created by Robert Barclay on 4/28/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCSMSConversationGroup.h"
#import "LocalContact.h"
#import "DID.h"
#import "Common.h"

@implementation JCSMSConversationGroup

@synthesize read          = _read;
@synthesize lastMessage   = _lastMessage;
@synthesize lastMessageId = _lastMessageId;
@synthesize date          = _date;


-(instancetype)initWithPhoneNumber:(id<JCPhoneNumberDataSource>)phoneNumber
{
    return [self initWithMessage:nil phoneNumber:phoneNumber];
}

-(instancetype)initWithMessage:(SMSMessage *)smsMessage phoneNumber:(id<JCPhoneNumberDataSource>)phoneNumber
{
    NSString *name;
    if (smsMessage) {
        name = smsMessage.localContact.name;
        if (!name) {
            name = phoneNumber.name;
        }
    }
    
    NSString *number = smsMessage.messageGroupId;
    if (!number && [phoneNumber respondsToSelector:@selector(internationalNumber)]) {
        number = phoneNumber.internationalNumber;
    }
    
    self = [super initWithName:name number:number];
    if (self) {
        if (smsMessage)
        {
            _read           = [self readStateForConversationGroupId:number context:smsMessage.managedObjectContext];
            _lastMessageId  = smsMessage.eventId;
            _lastMessage    = smsMessage.text;
            _date           = smsMessage.date;
            _didJrn         = smsMessage.did.jrn;
            _phoneNumber    = phoneNumber;
        }
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

-(BOOL)isSMS
{
    return TRUE;
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"%@ %@\n", self.titleText, self.detailText];
}

@end
