//
//  Conversation.m
//  JiveOne
//
//  Created by Robert Barclay on 1/12/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "Conversation.h"
#import "Contact.h"

@implementation Conversation

@dynamic contact;
@dynamic user;

-(NSString *)senderId
{
    if (self.contact) {
        return self.contact.jiveUserId;
    }
    return self.user.jiveUserId;
}

@end