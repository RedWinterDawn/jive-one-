//
//  JCBadgeManager.h
//  JiveOne
//
//  Created by Robert Barclay on 10/31/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
// Getting 'Use of '@import' when modules are disabled' when it's obviously enabled.

extern NSString *const kJCBadgeManagerInsertedIdentifierNotification;
extern NSString *const kJCBadgeManagerDeletedIdentifierNotification;
extern NSString *const kJCBadgeManagerIdentifierKey;

@interface JCBadgeManager : NSObject

// Total of all recent events badges.
@property (nonatomic, readonly) NSUInteger recentEvents;
@property (nonatomic, readonly) NSManagedObjectContext *managedObjectContext;

// Individual recent event types.
@property (nonatomic) NSUInteger voicemails;
@property (nonatomic, readonly) NSUInteger missedCalls;
@property (nonatomic, readonly) NSUInteger conversations;

@property (nonatomic, readonly) BOOL canSendNotifications;

-(void)initialize;
-(void)update;
-(void)reset;

// Manually tring an update from a background refresh.
-(void)startBackgroundUpdates;
-(NSUInteger)endBackgroundUpdates;



@end


@interface JCBadgeManager (Singleton)

+ (JCBadgeManager *)sharedManager;

+ (void)initialize;
+ (void)update;
+ (void)reset;

@end