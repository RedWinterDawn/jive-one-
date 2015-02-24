//
//  JCConversationGroup.h
//  JiveOne
//
//  Created by Robert Barclay on 2/23/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

@import Foundation;

@interface JCConversationGroup : NSObject

-(instancetype)initWithConversationId:(NSString *)conversationId;

@property (nonatomic, readonly) NSString *conversationId;
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *lastMessage;
@property (strong, nonatomic) NSDate *lastMessageReceived;

@end
