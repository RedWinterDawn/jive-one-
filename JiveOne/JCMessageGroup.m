//
//  JCSMSConversationGroup.m
//  JiveOne
//
//  Created by Robert Barclay on 4/28/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCMessageGroup.h"

#import "SMSMessage.h"
#import "PhoneNumber.h"

@interface JCMessageGroup ()
{
    Message *_latestMessage;
    NSArray *_messages;
}

@end


@implementation JCMessageGroup

-(instancetype)initWithMessageGroupId:(NSString *)messageGroupId
{
    self = [self initWithPhoneNumber:[[JCPhoneNumber alloc] initWithName:nil number:messageGroupId]];
    if(self) {
        _messageGroupId = messageGroupId;
    }
    return self;
}

-(instancetype)initWithPhoneNumber:(id<JCPhoneNumberDataSource>)phoneNumber
{
    self = [super init];
    if (self) {
        _phoneNumber = phoneNumber;
    }
    return self;
}

#pragma mark - Methods -

-(void)markAsSorted
{
    _needsSorting = FALSE;
}

-(void)markNeedUpdate
{
    _needsUpdate = TRUE;
}

#pragma mark - Setters -

-(void)setMessages:(NSArray *)messages
{
    _messages = messages;
    Message *firstMessage = messages.firstObject;
    if (_latestMessage && ![_latestMessage isEqual:firstMessage]) {
        _needsSorting = TRUE;
        _latestMessage = firstMessage;
    } else {
        _needsSorting = FALSE;
    }
}

-(NSArray *)messages
{
    if (_needsUpdate) {
        self.messages = [self.delegate updateMessagesForMessageGroup:self];
        _needsUpdate = FALSE;
        return _messages;
    }
    return _messages;
}

#pragma mark - Getters -

-(Message *)latestMessage
{
    if (_latestMessage) {
        return _latestMessage;
    }
    
    _latestMessage = self.messages.firstObject;
    return _latestMessage;
}

-(NSString *)titleText
{
    NSString *name = self.phoneNumber.name;
    if (name) {
        return name;
    }
    return self.formattedNumber;
}

-(NSString *)detailText
{
    Message *message = self.latestMessage;
    return message.text;
}

-(NSString *)formattedModifiedShortDate
{
    return self.latestMessage.formattedModifiedShortDate;
}

-(NSString *)formattedNumber
{
    return self.phoneNumber.formattedNumber;
}

-(NSString *)dialableNumber
{
    return self.phoneNumber.dialableNumber;
}

-(NSDate *)date
{
    return self.latestMessage.date;
}

-(BOOL)isRead
{
    NSArray *messages = self.messages;
    for (Message *message in messages) {
        if (!message.isRead) {
            return FALSE;
        }
    }
    return TRUE;
}

-(BOOL)isSMS
{
    Message *message = self.latestMessage;
    if ([message isKindOfClass:[SMSMessage class]]) {
        return TRUE;
    }
    return FALSE;
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"%@ %@\n", self.titleText, self.detailText];
}

@end
