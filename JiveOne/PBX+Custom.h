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

// Retrives the information for all PBXs and Lines attached to the user.
+ (void)downloadPbxInfoForUser:(User *)user completed:(void(^)(BOOL success, NSError *error))completion;

@end
