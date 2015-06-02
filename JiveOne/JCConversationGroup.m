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
#import "Common.h"
#import "DID.h"
#import "JCPhoneNumberDataSourceUtils.h"

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
            _date = message.date;
            _lastMessageId = message.eventId;
            _read = [self readStateForConversationGroupId:conversationGroupId context:context];
            if ([message isKindOfClass:[SMSMessage class]]) {
                SMSMessage *smsMessage = (SMSMessage *)message;
                _sms = TRUE;
                _name = smsMessage.localContact.name;
                _pbx = smsMessage.did.pbx;
            } else {
                //TODO: Chat functionality.
            }
        }
        [context refreshObject:message mergeChanges:NO];
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

-(NSString *)formattedModifiedShortDate
{
    return [Common formattedModifiedShortDate:self.date];
}

-(NSString *)description
{
    NSMutableString *output = [NSMutableString stringWithString:self.conversationGroupId];
    [output appendFormat:@" %@", self.date];
    return output;
}

#pragma mark - JCPhoneNumberDataSource -

#pragma mark - JCPhoneNumberDataSource Protocol -


-(NSString *)number
{
    return self.conversationGroupId;
}

-(NSString *)titleText
{
    NSString *name = self.name;
    if (name) {
        return name;
    }
    return [JCPhoneNumberDataSourceUtils formattedPhoneNumberForPhoneNumber:self];
}

-(NSString *)detailText
{
    return self.lastMessage;
}

-(NSString *)dialableNumber
{
    return [JCPhoneNumberDataSourceUtils dialableStringForPhoneNumber:self];
}

-(NSString *)t9
{
    return [JCPhoneNumberDataSourceUtils t9StringForPhoneNumber:self];
}

-(NSAttributedString *)titleTextWithKeyword:(NSString *)keyword font:(UIFont *)font color:(UIColor *)color
{
    return [JCPhoneNumberDataSourceUtils titleTextWithKeyword:keyword
                                                         font:font
                                                        color:color
                                                  phoneNumber:self];
}

-(NSAttributedString *)detailTextWithKeyword:(NSString *)keyword font:(UIFont *)font color:(UIColor *)color
{
    return [JCPhoneNumberDataSourceUtils detailTextWithKeyword:keyword
                                                          font:font
                                                         color:color
                                                   phoneNumber:self];
}

-(BOOL)containsKeyword:(NSString *)keyword
{
    return [JCPhoneNumberDataSourceUtils phoneNumber:self
                                     containsKeyword:keyword];
}

-(BOOL)containsT9Keyword:(NSString *)keyword
{
    return [JCPhoneNumberDataSourceUtils phoneNumber:self
                                   containsT9Keyword:keyword];
}

@end
