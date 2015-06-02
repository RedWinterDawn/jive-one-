//
//  SMSMessage.h
//  JiveOne
//
//  Created by Robert Barclay on 1/12/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "Message.h"

@class DID;
@class LocalContact;

extern NSString *const kSMSMessageInboundAttributeKey;

@interface SMSMessage : Message

// Attributes
@property (nonatomic, getter=isInbound) BOOL inbound;

// Relationships
@property (nonatomic, strong) DID *did;
@property (nonatomic, strong) LocalContact *localContact;

// Finds the DID from the didId, and attaches it to the message.
-(void)setDidId:(NSString *)didId;

// finds the local contact based on the number. If it does not exist, it creates it, setting the
// name if not nil. If it not yet attached to this message, it is attached.
-(void)setNumber:(NSString *)number name:(NSString *)name;

@end
