//
//  JCSocketLogger.h
//  JiveOne
//
//  Created by Robert Barclay on 3/19/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCSocketManager.h"

@interface JCSocketLogger : JCSocketManager

+(void)start;

+(void)logSocketEvent:(NSString *)eventName;

@end
