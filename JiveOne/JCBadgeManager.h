//
//  JCBadgeManager.h
//  JiveOne
//
//  Created by Robert Barclay on 10/31/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCManager.h"

@interface JCBadgeManager : JCManager

@property (nonatomic, readonly) NSUInteger recentEvents;    // Total Recent Events.
@property (nonatomic, readonly) NSUInteger voicemails;      // Total Unread Voicemails.
@property (nonatomic, readonly) NSUInteger missedCalls;     // Total Unread Missed Calls.
@property (nonatomic, readonly) NSUInteger smsMessages;		// Total Unread SMS Messages.

+ (void)updateBadgesFromContext:(NSManagedObjectContext *)context;
+ (void)reset;

+ (void)setVoicemails:(NSUInteger)voicemails;
+ (void)setSelectedLine:(NSString *)line;
+ (void)setSelectedPBX:(NSString *)pbx;

@end