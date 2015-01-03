//
//  PBX+V5Client.h
//  JiveOne
//
//  Retrives the information for all PBXs and Lines attached to the user using v5client.
//
//  Created by Eduardo Gueiros on 6/24/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "PBX.h"

@class User;

@interface PBX (V5Client)

+ (void)downloadPbxInfoForUser:(User *)user completed:(void(^)(BOOL success, NSError *error))completion;

@end
