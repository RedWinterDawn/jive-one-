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
@dynamic messageGroupId;

-(NSString *)senderId
{
    return nil; // should be overwritten by subclass
}

-(NSString *)senderDisplayName
{
    return nil; // should be overwritten by subclass
}

-(BOOL)isMediaMessage
{
    return NO;
}

-(NSString *)detailText {
    return self.formattedLongDate;
}

@end
