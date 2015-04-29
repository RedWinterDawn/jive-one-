//
//  JCConversationGroupEntityObject.h
//  JiveOne
//
//  Created by Robert Barclay on 4/28/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

@import Foundation;

#import "JCPhoneNumberDataSource.h"

@protocol JCConversationGroupObject <JCPhoneNumberDataSource>

@property (nonatomic, readonly, getter=isSMS) BOOL sms;
@property (nonatomic, readonly, getter=isRead) BOOL read;
@property (nonatomic, readonly) NSString *conversationGroupId;
@property (nonatomic, readonly) NSString *formattedModifiedShortDate;
@property (nonatomic, strong) NSString *lastMessageId;
@property (nonatomic, strong) NSString *lastMessage;
@property (nonatomic, strong) NSDate *date;

@end
