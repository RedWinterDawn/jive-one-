//
//  Presence+Custom.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 3/24/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "Presence.h"

@interface Presence (Custom)

+ (void)addPresences:(NSArray*)presences completed:(void (^)(BOOL succeeded))completed;
+ (Presence *)addPresence:(NSDictionary*)presence sender:(id)sender;
+ (Presence *)addPresence:(NSDictionary*)presence withManagedContext:(NSManagedObjectContext *)context sender:(id)sender;
+ (Presence *)updatePresence:(Presence *)presence dictionary:(NSDictionary *)dictionary withManagedContext:(NSManagedObjectContext *)context;

@end
