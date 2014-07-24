//
//  PersonEntities+Custom.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 4/18/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "PersonEntities.h"

@interface PersonEntities (Custom)

+ (void)addEntities:(NSArray *)entities me:(NSString *)me completed:(void (^)(BOOL success))completed;
+ (PersonEntities *)addEntity:(NSDictionary*)entity me:(NSString *)me sender:(id)sender;
+ (PersonEntities *)addEntity:(NSDictionary*)entity me:(NSString *)me withManagedContext:(NSManagedObjectContext *)context sender:(id)sender;
+ (void)updateEntities:(PersonEntities *)entity withDictionary:(NSDictionary *)dictionary withManagedContext:(NSManagedObjectContext *)context;;
@end


