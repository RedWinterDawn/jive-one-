//
//  Presence+Custom.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 3/24/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "Presence+Custom.h"

@implementation Presence (Custom)



+ (void)addPresences:(NSArray*)presences completed:(void (^)(BOOL))completed
{
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        for (NSDictionary *presence in presences) {
            if ([presence isKindOfClass:[NSDictionary class]]) {
                [self addPresence:presence sender:self];
            }
        }
    } completion:^(BOOL success, NSError *error) {
        completed(success);
    }];
    
    
}

+ (Presence *)addPresence:(NSDictionary*)presence sender:(id)sender
{
    return [self addPresence:presence withManagedContext:nil sender:sender];
}


+ (Presence *)addPresence:(NSDictionary*)presence withManagedContext:(NSManagedObjectContext *)context sender:(id)sender
{
    
    if (!context) {
        context = [NSManagedObjectContext MR_contextForCurrentThread];
    }
    
    NSString *presenceId = presence[@"id"];
    NSArray *result = [Presence MR_findByAttribute:@"presenceId" withValue:presenceId];
    Presence *pres = nil;
    
    if (result.count > 0) {
        pres = result[0];
        pres = [self updatePresence:pres dictionary:presence withManagedContext:context];
    }
    else
    {
        pres = [Presence MR_createInContext:context];
        pres.entityId = presence[@"entity"];
        pres.lastModified = presence[@"lastModified"];
        pres.createDate = presence[@"createDate"];
        pres.interactions = presence[@"interactions"];
        //pres.urn = presence[@"urn"];
        pres.presenceId = presence[@"id"];
        
        // update presence for asscociated entity
        [[JCOmniPresence sharedInstance] entityByEntityId:pres.entityId].entityPresence = pres;
        
        
        
    }
    
    if (self != sender) {
        [context MR_saveToPersistentStoreAndWait];
        return pres;
    }
    else {
        return nil;
    }
}

+ (Presence *)updatePresence:(Presence *)presence dictionary:(NSDictionary *)dictionary withManagedContext:(NSManagedObjectContext *)context
{
    if (!context) {
        context = [NSManagedObjectContext MR_contextForCurrentThread];
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
        }
    }
    
    return presence;
}


@end
