//
//  LineConfiguration+Custom.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 9/30/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "LineConfiguration.h"

@interface LineConfiguration (Custom)
+ (void)addConfiguration:(NSDictionary *)config line:(Line *)line completed:(void (^)(BOOL success, NSError *error))completed;
@end
