//
//  Presence+Custom.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 3/24/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "Presence.h"

@interface Presence (Custom)

+ (void)addPresences:(NSArray*)presences;
+ (Presence *)addPresence:(NSDictionary*)presence;
+ (Presence *)addPresence:(NSDictionary*)presence withManagedContext:(NSManagedObjectContext *)context;
+ (Presence *)updatePresence:(Presence *)presence dictionary:(NSDictionary *)dictionary withManagedContext:(NSManagedObjectContext *)context;

@end
