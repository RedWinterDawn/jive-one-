//
//  JCBadgeManagerBatchOperation.m
//  JiveOne
//
//  In this NSOperation subclass, we take the update dictionary form a core data Context Save
//  Notification and iterate through each managed object event to determine if it is a badgeable
//  item, parse through the results, and update or remove items from the badge multidimenional
//  array.
//
//  Created by Robert Barclay on 12/19/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCBadgeManagerBatchOperation.h"

#import "JCBadgeManager.h"

#import "MissedCall.h"
#import "Voicemail.h"
#import "RecentLineEvent.h"
#import "Message.h"
#import "SMSMessage.h"

NSString *const kJCBadgeManagerBatchVoicemailsKey    = @"voicemails";
NSString *const kJCBadgeManagerBatchMissedCallsKey   = @"missedCalls";
NSString *const kJCBadgeManagerBatchConversationsKey = @"conversations";
NSString *const kJCBadgeManagerBatchSMSMessagesKey   = @"smsMessages";


@interface JCBadgeManagerBatchOperation ()
{
    NSDictionary *_updateDictionary;
    NSMutableDictionary *_badges;
    BOOL _updated;
}

@end

@implementation JCBadgeManagerBatchOperation

-(instancetype)initWithDictionaryUpdate:(NSDictionary *)updateDictionary
{
    self = [super init];
    if (self) {
        _updateDictionary = updateDictionary;
    }
    return self;
}


-(void)main {
    _badges = [JCBadgeManager sharedManager].badges;
    
    NSManagedObjectContext *context = [NSManagedObjectContext MR_rootSavingContext];
    [self processUpdateDictionaryForInfoKey:NSInsertedObjectsKey context:context];
    [self processUpdateDictionaryForInfoKey:NSUpdatedObjectsKey context:context];
    [self processUpdateDictionaryForInfoKey:NSDeletedObjectsKey context:context];
    
    if (_updated) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [JCBadgeManager sharedManager].badges = _badges;
        });
    }
}

-(void)processUpdateDictionaryForInfoKey:(NSString *)key context:(NSManagedObjectContext *)context
{
    // Check to see if we have a set for the info key. Exit if we do not. The object being passed
    // should be a NSSet object. If it is not, we exit.
    id object = [_updateDictionary objectForKey:key];
    if (!object || ![object isKindOfClass:[NSSet class]]) {
        return;
    }
    
    // Pull out our set and iterate over each of the objects in the set. Objects should be
    // NSManagedObjects. Process the managed object.
    NSSet *set = (NSSet *)object;
    for (id item in set) {
        if ([item isKindOfClass:[NSManagedObject class]]) {
            NSManagedObject *managedObject = [context objectWithID:((NSManagedObject *)item).objectID];
            [self processManagedObject:managedObject forInfoKey:key];
        }
    }
}

-(void)processManagedObject:(NSManagedObject *)object forInfoKey:(NSString *)infoKey
{
    if (![object isKindOfClass:[RecentEvent class]])
        return;
    
    RecentEvent *recentEvent = (RecentEvent *)object;
    NSString *eventType = [self eventTypeFromRecentEvent:recentEvent];
    if (!eventType) {
        return;
    }
    
    BOOL insert = [infoKey isEqualToString:NSInsertedObjectsKey];
    BOOL update = [infoKey isEqualToString:NSUpdatedObjectsKey];
    BOOL delete = [infoKey isEqualToString:NSDeletedObjectsKey];
    
    _updated = TRUE;
    NSString *key = recentEvent.objectID.URIRepresentation.absoluteString;
    if (delete) {
        NSArray *eventGroupingKeys = _badges.allKeys;
        for (NSString *eventGroupingKey in eventGroupingKeys) {
            NSMutableDictionary *events = [self eventsForEventType:eventType forKey:eventGroupingKey];
            if ([events objectForKey:key]) {
                [events removeObjectForKey:key];
            }
            [self setEvents:events forEventType:eventType forKey:eventGroupingKey];
        }
    }
    else
    {
        NSString *eventGroupingKey = [self eventGroupingKeyForRecentEvent:recentEvent];
        if (!eventGroupingKey) {
            return;
        }
        
        BOOL read = recentEvent.isRead;
        NSMutableDictionary *events = [self eventsForEventType:eventType forKey:eventGroupingKey];
        if (insert && !read) {
            [events setObject:@NO forKey:key];
        }
        else if (update) {
            if (!read) {
                [events setObject:@NO forKey:key];
            }
            else {
                [events removeObjectForKey:key];
            }
        }
        [self setEvents:events forEventType:eventType forKey:eventGroupingKey];
    }
}

-(NSString *)eventGroupingKeyForRecentEvent:(RecentEvent *)recentEvent
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

/**
 * Returns a identifier key for a given recent event based on the kind of object.
 *
 * The Identifier key returned is used thoughout the badge system to categorize a recent event into
 * a bucket. The bucket count provides us the badge numbers for a given key.
 */
-(NSString *)eventTypeFromRecentEvent:(RecentEvent *)recentEvent
{
    if ([recentEvent isKindOfClass:[MissedCall class]]) {
        return kJCBadgeManagerBatchMissedCallsKey;
    }
    else if ([recentEvent isKindOfClass:[Voicemail class]]) {
        return kJCBadgeManagerBatchVoicemailsKey;
    }
    else if ([recentEvent isKindOfClass:[SMSMessage class]]) {
        return kJCBadgeManagerBatchSMSMessagesKey;
    }
    return nil;
}

-(void)setEvents:(NSDictionary *)events forEventType:(NSString *)type forKey:(NSString *)key
{
    NSMutableDictionary *eventTypes = [self eventTypesForKey:key];
    [eventTypes setObject:events forKey:type];
    [self setEventTypes:eventTypes forKey:key];
}

-(NSMutableDictionary *)eventsForEventType:(NSString *)type forKey:(NSString *)key
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
-(void)setEventTypes:(NSDictionary *)types forKey:(NSString *)key
{
    [_badges setObject:types forKey:key];
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
    id object = [_badges objectForKey:key];
    if ([object isKindOfClass:[NSDictionary class]]){
        NSDictionary *events = (NSDictionary *)object;
        return [NSMutableDictionary dictionaryWithDictionary:events];
    }
    return [NSMutableDictionary dictionary];
}

@end
