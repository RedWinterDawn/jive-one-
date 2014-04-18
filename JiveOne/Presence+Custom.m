//
//  Presence+Custom.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 3/24/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "Presence+Custom.h"

@implementation Presence (Custom)

static NSManagedObjectContext *_context;

+ (void)addPresences:(NSArray*)presences
{
    for (NSDictionary *presence in presences) {
        if ([presence isKindOfClass:[NSDictionary class]]) {
            [self addPresence:presence];
        }
    }
}

+ (Presence *)addPresence:(NSDictionary*)presence
{
    return [self addPresence:presence withManagedContext:nil];
}


+ (Presence *)addPresence:(NSDictionary*)presence withManagedContext:(NSManagedObjectContext *)context
{
    
    if (context) {
        _context = context;
    }
    else {
        _context = [NSManagedObjectContext MR_contextForCurrentThread];
    }
    
    NSString *presenceId = presence[@"id"];
    NSArray *result = [Presence MR_findByAttribute:@"presenceId" withValue:presenceId];
    Presence *pres = nil;
    
    if (result.count > 0) {
        pres = result[0];
        return [self updatePresence:pres dictionary:presence withManagedContext:_context];
    }
    else
    {
        pres = [Presence MR_createInContext:_context];
        pres.entityId = presence[@"entity"];
        pres.lastModified = presence[@"lastModified"];
        pres.createDate = presence[@"createDate"];
        pres.interactions = presence[@"interactions"];
        //pres.urn = presence[@"urn"];
        pres.presenceId = presence[@"id"];
        
        // update presence for asscociated entity
        [[JCOmniPresence sharedInstance] entityByEntityId:pres.entityId].entityPresence = pres;
        
        [_context MR_saveToPersistentStoreAndWait];
    }
    
    return pres;
}

+ (Presence *)updatePresence:(Presence *)presence dictionary:(NSDictionary *)dictionary withManagedContext:(NSManagedObjectContext *)context
{
    if (context) {
        _context = context;
    }
    else {
        _context = [NSManagedObjectContext MR_contextForCurrentThread];
    }
    
    long lastModifiedFromEntity = [presence.lastModified integerValue];
    long lastModifiedFromDictionary = [dictionary[@"lastModified"] integerValue];
    
    if (lastModifiedFromDictionary != lastModifiedFromEntity) {
        presence.entityId = dictionary[@"entity"];
        presence.lastModified = dictionary[@"lastModified"];
        //presence.createDate = dictionary[@"createDate"];
        presence.interactions = dictionary[@"interactions"];
        //pres.urn = presence[@"urn"];
        //presence.presenceId = dictionary[@"id"];
        
        // update presence for asscociated entity
        if (presence.interactions) {
            [[JCOmniPresence sharedInstance] entityByEntityId:presence.entityId].entityPresence = presence;
            
            [_context MR_saveToPersistentStoreAndWait];
        }
    }
    
    return presence;
}


@end
