//
//  JCSocketManager.m
//  JiveOne
//
//  Created by Robert Barclay on 3/17/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCSocketManager.h"

NSString *const kJCSocketManagerTypeKey = @"type";
NSString *const kJCSocketManagerDataKey = @"entity";

NSString *const kJCSocketManagerTypeKeepAlive = @"keepalive";

@implementation JCSocketManager

-(instancetype)init
{
    self = [super init];
    if (self) {
        _socket = [JCSocket sharedSocket];
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(socketDidReceiveMessageSelector:) name:kJCSocketReceivedDataNotification object:_socket];
    }
    return self;
}

-(void)socketDidReceiveMessageSelector:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    NSDictionary *results = [userInfo objectForKey:kJCSocketNotificationResultKey];
    if (!results) {
        NSError *error = [userInfo objectForKey:kJCSocketNotificationErrorKey];
        NSLog(@"Socket Error: %@", [error description]);
        return;
    }
    
    // Get the event message type.
    NSString *type = [results stringValueForKey:kJCSocketManagerTypeKey];
    
    // Get the event message data.
    NSDictionary *data = nil;
    id object = [results objectForKey:kJCSocketManagerDataKey];
    if (object && [object isKindOfClass:[NSDictionary class]]) {
        data = (NSDictionary *)object;
    }
    [self receivedResult:results type:type data:data];
    NSLog(@"data through sockets : %@",data);
}

-(void)receivedResult:(NSDictionary *)result type:(NSString *)type data:(NSDictionary *)data
{
    NSLog(@" The result of scckets : %@", result);
}

@end
