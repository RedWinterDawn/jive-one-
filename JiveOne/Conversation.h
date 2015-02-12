//
//  Conversation.h
//  JiveOne
//
//  Created by Robert Barclay on 1/12/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "Message.h"

@class Contact;
@class User;

@interface Conversation : Message

// Attributes
@property (nonatomic, retain) NSString * conversationId;

// Relationships
@property (nonatomic, retain) Contact *contact;
@property (nonatomic, retain) Contact *user;

@end
