//
//  Conversation.m
//  JiveOne
//
//  Created by Robert Barclay on 1/12/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "Conversation.h"


@implementation Conversation

@dynamic jiveUserId;

-(NSString *)senderId
{
    return self.jiveUserId;
}

@end
