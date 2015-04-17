//
//  JCConversationGroup.h
//  JiveOne
//
//  Created by Robert Barclay on 2/23/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

@import Foundation;

#import "JCPhoneNumber.h"

@interface JCConversationGroup : NSObject <JCPhoneNumberDataSource>

-(instancetype)initWithConversationGroupId:(NSString *)conversationGroupId context:(NSManagedObjectContext *)context;

@property (nonatomic, readonly, getter=isSMS) BOOL sms;
@property (nonatomic, readonly, getter=isRead) BOOL read;

@property (nonatomic, readonly) NSString *conversationGroupId;
@property (nonatomic, readonly) PBX *pbx;

@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *lastMessage;
@property (strong, nonatomic) NSDate *date;
@property (strong, nonatomic) NSString *lastMessageId;

@property (nonatomic, readonly) NSString *formattedModifiedShortDate;
@property (nonatomic, readonly) NSString *formattedPhoneNumber;


@end
