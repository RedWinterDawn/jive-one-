//
//  JCSocketManager.m
//  JiveOne
//
//  Created by Robert Barclay on 3/17/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCSocketManager.h"

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
    NSLog(@"%@", userInfo);
}

@end

@implementation JCSocketManager (Singleton)

+(instancetype)sharedManager
{
    static id singleton = nil;
    static dispatch_once_t loaded;
    dispatch_once(&loaded, ^{
        singleton = [[self class] new];
    });
    return singleton;
}

+ (id)copyWithZone:(NSZone *)zone
{
    return self;
}

@end
