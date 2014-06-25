//
//  Lines+Custom.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 6/24/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "Lines.h"

@interface Lines (Custom)

+ (void)addLines:(NSArray *)lines pbxId:(NSString *)pbxId completed:(void (^)(BOOL success))completed;;
+ (Lines *)addLine:(NSDictionary *)line pbxId:(NSString *)pbxId withManagedContext:(NSManagedObjectContext *)context sender:(id)sender;

@end
