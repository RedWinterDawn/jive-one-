//
//  PersonEntities+Custom.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 4/18/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "PersonEntities.h"

@interface PersonEntities (Custom)

+ (void)addEntities:(NSArray *)entities me:(NSString *)me;
+ (PersonEntities *)addEntity:(NSDictionary*)entity me:(NSString *)me;
+ (PersonEntities *)addEntity:(NSDictionary*)entity me:(NSString *)me withManagedContext:(NSManagedObjectContext *)context;
+ (PersonEntities *)updateEntities:(PersonEntities *)entity withDictionary:(NSDictionary *)dictionary withManagedContext:(NSManagedObjectContext *)context;;
@end
