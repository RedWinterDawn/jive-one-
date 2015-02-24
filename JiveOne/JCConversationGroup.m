//
//  JCConversationGroup.m
//  JiveOne
//
//  Created by Robert Barclay on 2/23/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCConversationGroup.h"

@implementation JCConversationGroup

-(instancetype)initWithConversationId:(NSString *)conversationId
{
    self = [super init];
    if (self) {
        _conversationId = conversationId;
    }
    return self;
}


@end
