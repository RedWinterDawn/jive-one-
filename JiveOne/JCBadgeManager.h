//
//  JCBadgeManager.h
//  JiveOne
//
//  Created by Robert Barclay on 10/31/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JCBadgeManager : NSObject

@property (nonatomic, readonly) NSUInteger recentEvents;    // Total Recent Events.
@property (nonatomic, readonly) NSUInteger voicemails;      // Total Unread Voicemails.
@property (nonatomic, readonly) NSUInteger missedCalls;     // Total Unread Missed Calls.

@end

@interface JCBadgeManager (Singleton)

+ (JCBadgeManager *)sharedManager;
+ (void)updateBadgesFromContext:(NSManagedObjectContext *)context;
+ (void)reset;

+ (void)setVoicemails:(NSUInteger)voicemails;
+ (void)setSelectedLine:(NSString *)line;

@end