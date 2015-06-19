//
//  Conversation.h
//  JiveOne
//
//  Created by Robert Barclay on 1/12/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "Message.h"

@class InternalExtension;
@class User;

@interface Conversation : Message

// Relationships
@property (nonatomic, retain) InternalExtension *internalExtension;
@property (nonatomic, retain) InternalExtension *user;

@end
