//
//  Message.m
//  JiveOne
//
//  Created by Robert Barclay on 1/12/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "Message.h"


@implementation Message

@dynamic text;
@dynamic conversationId;

-(NSString *)senderId
{
    return self.number;
}

-(NSString *)senderDisplayName
{
    return self.name;
}

-(BOOL)isMediaMessage
{
    return NO;
}

-(NSString *)detailText {
    return self.formattedLongDate;
}

@end
