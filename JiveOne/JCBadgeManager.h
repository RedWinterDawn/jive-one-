//
//  JCBadgeManager.h
//  JiveOne
//
//  Created by Robert Barclay on 10/31/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

@import Foundation;

extern NSString *const kJCBadgeManagerInsertedIdentifierNotification;
extern NSString *const kJCBadgeManagerDeletedIdentifierNotification;
extern NSString *const kJCBadgeManagerIdentifierKey;

@interface JCBadgeManager : NSObject

// Total of all recent events badges.
@property (nonatomic, readonly) NSUInteger recentEvents;
@property (nonatomic, readonly) NSManagedObjectContext *managedObjectContext;

// Individual recent event types.
@property (nonatomic, readonly) NSUInteger voicemails;
@property (nonatomic, readonly) NSUInteger missedCalls;
@property (nonatomic, readonly) NSUInteger conversations;

@property (nonatomic, readonly) BOOL canSendNotifications;
@property (nonatomic) BOOL saveToPersistantStore;

-(void)initialize;

// Manually trigger an update.
-(void)update;

// Manually tring an update from a background refresh.
-(void)startBackgroundUpdates;
-(NSUInteger)endBackgroundUpdates;

-(void)reset;

@end


@interface JCBadgeManager (Singleton)

+ (JCBadgeManager *)sharedManager;

@end