//
//  JCSocketLogger.m
//  JiveOne
//
//  Created by Robert Barclay on 3/19/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCSocketLogger.h"

@implementation JCSocketLogger

+(void)start
{
    [[JCSocketLogger sharedManager] start];
}

+(void)logSocketEvent:(NSString *)eventName
{
    [[JCSocketLogger sharedManager] logSocketEvent:eventName];
}

-(void)start
{
    [self logSocketEvent:@"Starting Logging Socket Events"];
}

-(void)logSocketEvent:(NSString *)socketEvent
{
    NSLog(@"%@", socketEvent);
}

-(void)receivedResult:(NSDictionary *)result type:(NSString *)type data:(NSDictionary *)data
{
    if (!data) {
        [self logSocketEvent:type];
        return;
    }
    [self logSocketEvent:[NSString stringWithFormat:@"%@\n%@", type, data]];
}

@end
