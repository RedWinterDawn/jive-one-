//
//  JCBadges.h
//  JiveOne
//
//  This class acts as a data structure to creating, and reading from the Multidimensional data
//  structure that holds the badges.
//
//  It can be initialized with an initial badges data structure, manipulated through the processing
//  of recent event core data objects, and the ability to read from that data structure by event
//  types and keys they was stored under.
//
//  The resulting raw data structure can be retrived for storage after manipulation for batch
//  operations.
//
//  Created by Robert Barclay on 3/5/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

@import Foundation;

@class RecentEvent;

extern NSString *const kJCBadgesVoicemailsEventTypeKey;
extern NSString *const kJCBadgesMissedCallsEventTypeKey;
extern NSString *const kJCBadgesSMSMessagesEventTypeKey;

@interface JCBadges : NSObject <NSCopying>

@property (nonatomic, readonly) NSDictionary *badgeData;

- (instancetype)initWithBadgeData:(NSDictionary *)dictionary;

// Modification of the badges.
- (void)processRecentEvents:(NSArray *)recentEvents;
- (void)processRecentEvent:(RecentEvent *)recentEvent;
- (void)addRecentEvent:(RecentEvent *)recentEvent;
- (void)removeRecentEvent:(RecentEvent *)recentEvent;

// Fetching recent events using event type and keys.
- (NSMutableDictionary *)eventsForEventType:(NSString *)type key:(NSString *)key;
- (NSMutableDictionary *)eventTypesForKey:(NSString *)key;
- (NSUInteger)countForEventType:(NSString *)eventType key:(NSString *)key;

// Setting a recent event type with key.
- (void)setEventTypes:(NSDictionary *)eventTypes key:(NSString *)key;

@end
