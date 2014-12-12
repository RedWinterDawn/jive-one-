//
//  Lines+Custom.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 6/24/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "Line.h"

@class PBX;

@interface Line (Custom)

+ (void)addLines:(NSArray *)linesData pbx:(PBX *)pbx completed:(void (^)(BOOL success, NSError *error))completed;
+ (Line *)addLine:(NSDictionary *)lineData pbx:(PBX *)pbx;

@end
