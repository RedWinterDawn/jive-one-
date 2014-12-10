//
//  PBX+Custom.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 6/24/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "PBX.h"

@class User;

@interface PBX (Custom)

+ (void)addPBXs:(NSArray *)pbxsData user:(User *)user completed:(void (^)(BOOL success, NSArray *pbxs, NSError *error))completed;

+ (PBX *)addPBX:(NSDictionary *)data user:(User *)user context:(NSManagedObjectContext *)context;

@end
