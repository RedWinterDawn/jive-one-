//
//  JCMessageGroup.h
//  JiveOne
//
//  Created by Robert Barclay on 4/28/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "Message.h"
#import <JCPhoneModule/JCPhoneModule.h>

@class DID;

@protocol JCMessageGroupDelegate;

@interface JCMessageGroup : NSObject

-(instancetype)initWithGroupId:(NSString *)groupId resourceId:(NSString *)resourceId;
-(instancetype)initWithPhoneNumber:(id<JCPhoneNumberDataSource>)phoneNumber resourceId:(NSString *)resouceId;

@property (nonatomic, weak) id<JCMessageGroupDelegate> delegate;

@property (nonatomic, strong) id<JCPhoneNumberDataSource> phoneNumber;
@property (nonatomic, strong) NSArray *messages;
@property (nonatomic, strong) NSString *resourceId;
@property (nonatomic, strong) NSString *groupId;

@property (nonatomic, readonly) NSDate *date;
@property (nonatomic, readonly) NSString *formattedModifiedShortDate;
@property (nonatomic, readonly) NSString *titleText;
@property (nonatomic, readonly) NSString *detailText;

@property (nonatomic, readonly) Message *latestMessage;
//@property (nonatomic, readonly) DID *did;
@property (nonatomic, readonly) User *user;
@property (nonatomic, readonly) BOOL isSMS;
@property (nonatomic, readonly) BOOL isRead;
@property (nonatomic, readonly) BOOL needsSorting;
@property (nonatomic, readonly) BOOL needsUpdate;

-(void)markNeedUpdate;
-(void)markAsSorted;

@end

@protocol JCMessageGroupDelegate <NSObject>

-(NSArray *)updateMessagesForMessageGroup:(JCMessageGroup *)messageGroup;

@end