//
//  PBX+Custom.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 6/24/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "PBX.h"


@interface PBX (Custom)

+ (void)addPBXs:(NSArray *)pbxs completed:(void (^)(BOOL success))completed;;
+ (PBX *)addPBX:(NSDictionary *)pbx withManagedContext:(NSManagedObjectContext *)context sender:(id)sender;


@end
