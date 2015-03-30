//
//  JCBadges.m
//  JiveOne
//
//  Created by Robert Barclay on 3/5/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCBadges.h"

#import "RecentEvent.h"
#import "RecentLineEvent.h"
#import "MissedCall.h"
#import "Voicemail.h"
#import "SMSMessage.h"
#import "PBX.h"

NSString *const kJCBadgesVoicemailsEventTypeKey    = @"voicemails";
NSString *const kJCBadgesMissedCallsEventTypeKey   = @"missedCalls";
NSString *const kJCBadgesSMSMessagesEventTypeKey   = @"smsMessages";

@interface JCBadges () {
    NSMutableDictionary *_badgeData;
}

@end

@implementation JCBadges

-(instancetype)initWithBadgeData:(NSDictionary *)dictionary
{
    self = [super init];
    if (self) {
        _badgeData = [NSMutableDictionary dictionaryWithDictionary:dictionary];
    }
    return self;
}

-(instancetype)init
{
    self = [super init];
    if (self) {
        _badgeData = [NSMutableDictionary dictionary];
    }
    return self;
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    return [[[self class] allocWithZone:zone] initWithBadgeData:_badgeData.copy];
}

-(void)processRecentEvents:(NSArray *)recentEvents
{
    for (RecentEvent *recentEvent in recentEvents) {
        [self processRecentEvent:recentEvent];
    }
    
    NSLog(@"%@", _badgeData);
}

-(void)processRecentEvent:(RecentEvent *)recentEvent
{
    BOOL read = recentEvent.isRead;
    if (read) {
        [self removeRecentEvent:recentEvent];
    } else {
        [self addRecentEvent:recentEvent];
    }
}

-(void)addRecentEvent:(RecentEvent *)recentEvent
{
    // We only add recent events if they are not read.
    if (recentEvent.isRead) {
        return;
    }
    
    NSString *eventType = [self eventTypeFromRecentEvent:recentEvent];
    if (!eventType) {
        return;
    }
    
    NSString *objectId = recentEvent.objectID.URIRepresentation.absoluteString;
    NSString *key = [self keyForRecentEvent:recentEvent];
    NSMutableDictionary *events = [self eventsForEventType:eventType key:key];
    [events setObject:@NO forKey:objectId];
    [self setEvents:events forEventType:eventType key:key];
    NSLog(@"%@", _badgeData);
}

-(void)removeRecentEvent:(RecentEvent *)recentEvent
{
    NSString *eventType = [self eventTypeFromRecentEvent:recentEvent];
    if (!eventType) {
        return;
    }
    
    NSString *objectId = recentEvent.objectID.URIRepresentation.absoluteString;
    NSString *key = [self keyForRecentEvent:recentEvent];
    if (!key) {
        return;
    }
    
    NSMutableDictionary *events = [self eventsForEventType:eventType key:key];
    if ([events objectForKey:objectId]) {
        [events removeObjectForKey:objectId];
    }
    [self setEvents:events forEventType:eventType key:key];
    NSLog(@"%@", _badgeData);
}

-(NSString *)keyForRecentEvent:(RecentEvent *)recentEvent
{
    if ([recentEvent isKindOfClass:[RecentLineEvent class]])
    {
        Line *lineObject = ((RecentLineEvent *)recentEvent).line;
        if (!lineObject) {
            return nil;
        }
        
        NSString *line = lineObject.jrn;
        if (!line || line.length == 0) {
            return nil;
        }
        return line;
        
    }
    else if([recentEvent isKindOfClass:[SMSMessage class]])
    {
        PBX *pbx = ((SMSMessage *)recentEvent).did.pbx;
        if (!pbx) {
            return nil;
        }
        
        NSString *pbxId = pbx.pbxId;
        if (!pbxId || pbxId.length == 0) {
            return nil;
        }
        return pbxId;
    }
    return nil;
}


#pragma mark - Private -

/**
 * Returns a identifier key for a given recent event based on the kind of object.
 *
 * The Identifier key returned is used thoughout the badge system to categorize a recent event into
 * a bucket. The bucket count provides us the badge numbers for a given key.
 */
-(NSString *)eventTypeFromRecentEvent:(RecentEvent *)recentEvent
{
    if ([recentEvent isKindOfClass:[MissedCall class]]) {
        return kJCBadgesMissedCallsEventTypeKey;
    }
    else if ([recentEvent isKindOfClass:[Voicemail class]]) {
        return kJCBadgesVoicemailsEventTypeKey;
    }
    else if ([recentEvent isKindOfClass:[SMSMessage class]]) {
        return kJCBadgesSMSMessagesEventTypeKey;
    }
    return nil;
}

-(void)setEvents:(NSDictionary *)events forEventType:(NSString *)type key:(NSString *)key
{
    NSMutableDictionary *eventTypes = [self eventTypesForKey:key];
    [eventTypes setObject:events forKey:type];
    [self setEventTypes:eventTypes key:key];
}

-(NSMutableDictionary *)eventsForEventType:(NSString *)type key:(NSString *)key
{
    NSMutableDictionary *events = [self eventTypesForKey:key];
    id object = [events objectForKey:type];
    if ([object isKindOfClass:[NSDictionary class]]) {
        return [NSMutableDictionary dictionaryWithDictionary:(NSDictionary *)object];
    }
    return [NSMutableDictionary dictionary];
}

/**
 * Sets the event types for a given line in the badges dictionary.
 *
 * Overrites the existing value of the badges dictionary for a given line. If was empty, it is
 * created, otherwise replaced with the new values.
 */
-(void)setEventTypes:(NSDictionary *)types key:(NSString *)key
{
    [_badgeData setObject:types forKey:key];
}

/**
 * Retrives the event types from the badges array for the given line.
 *
 * Each line maintains a seperate dictionary of events types. We try to retrive from the badges
 * object a dictionary corresponding to the line identifier. If we have a dictionary for that key,
 * we return a mutable form of it. If not, we return a new empty mutable dictionary.
 */
-(NSMutableDictionary *)eventTypesForKey:(NSString *)key
{
    id object = [_badgeData objectForKey:key];
    if ([object isKindOfClass:[NSDictionary class]]){
        NSDictionary *events = (NSDictionary *)object;
        return [NSMutableDictionary dictionaryWithDictionary:events];
    }
    return [NSMutableDictionary dictionary];
}

-(NSUInteger)countForEventType:(NSString *)eventType key:(NSString *)key
{
    NSDictionary *events = [self eventsForEventType:eventType key:key];
    return events.allKeys.count;
}

@end
