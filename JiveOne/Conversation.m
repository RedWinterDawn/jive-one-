//
//  Conversation.m
//  JiveOne
//
//  Created by Robert Barclay on 1/12/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "Conversation.h"
#import "InternalExtension.h"

@implementation Conversation

@dynamic internalExtension;
@dynamic user;

-(NSString *)senderId
{
    if (self.internalExtension) {
        return self.internalExtension.jiveUserId;
    }
    return self.user.jiveUserId;
}

@end