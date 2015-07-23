//
//  JCSocketManager.m
//  JiveOne
//
//  Created by Robert Barclay on 3/17/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCSocketManager.h"
#import "PBX.h"

#define SOCKET_SUBSCRIPTION_BATCH_SIZE_LIMIT 5

NSString *const kJCSocketManagerTypeKeepAlive   = @"keepalive";

NSString *const kJCSocketManagerSubscriptionIdKey                   = @"id";
NSString *const kJCSocketManagerSubscriptionTypeKey                 = @"type";
NSString *const kJCSocketManagerSubscriptionEntityKey               = @"entity";
NSString *const kJCSocketManagerSubscriptionEntityIdentifierKey         = @"id";
NSString *const kJCSocketManagerSubscriptionEntityTypeKey               = @"type";
NSString *const kJCSocketManagerSubscriptionEntityAccountKey            = @"account";

NSString *const kJCSocketManagerEventTypeKey                        = @"type";
NSString *const kJCSocketManagerEventDataKey                        = @"data";

static NSMutableArray *subscriptions;

@implementation JCSocketManager

+(void)subscribe
{
    JCSocketManager *socketManager = [JCSocketManager sharedManager];
    [socketManager subscribe];
}

+(void)unsubscribe:(CompletionHandler)completion
{
    JCSocketManager *socketManager = [JCSocketManager sharedManager];
    [socketManager unsubscribe:completion];
}

-(instancetype)init
{
    return [self initWithSocket:[JCSocket sharedSocket]
                    appSettings:[JCAppSettings sharedSettings]];
}

-(instancetype)initWithSocket:(JCSocket *)socket appSettings:(JCAppSettings *)appSettings
{
    self = [super init];
    if (self) {
        _socket = [JCSocket sharedSocket];
        _appSettings = appSettings;
        _batchSize = SOCKET_SUBSCRIPTION_BATCH_SIZE_LIMIT;
        
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(socketDidReceiveMessageSelector:) name:kJCSocketReceivedDataNotification object:_socket];
        
    }
    return self;
}

-(void)unsubscribe:(CompletionHandler)completion
{
    if (subscriptions) {
        subscriptions = nil;
    }
    
    [_socket unsubscribeToSocketEvents:completion];
}

-(void)subscribe
{
    NSMutableArray *mutableSubset = nil;
    if (_batchSize > 0) {
        for (NSDictionary *subscription in subscriptions) {
            if(!mutableSubset) {
                mutableSubset = [NSMutableArray new];
            }
            
            [mutableSubset addObject:subscription];
            if (mutableSubset.count == _batchSize) {
                [JCSocket subscribeToSocketEventsWithArray:mutableSubset];
                mutableSubset = nil;
            }
        }
        
        if (mutableSubset) {
            [_socket subscribeToSocketEventsWithArray:mutableSubset];
        }
    } else {
        [_socket subscribeToSocketEventsWithArray:subscriptions];
    }
    subscriptions = nil;
}

-(void)generateSubscriptionWithIdentifier:(NSString *)identifier type:(NSString *)type entityType:(NSString *)entityType entityId:(NSString *)entityId entityAccountId:(NSString *)entityAccountId;
{
    NSDictionary *entity = @{kJCSocketManagerSubscriptionEntityIdentifierKey:entityId,
                             kJCSocketManagerSubscriptionEntityTypeKey:entityType,
                             kJCSocketManagerSubscriptionEntityAccountKey:entityAccountId};

    NSDictionary *requestParameters = [self subscriptionDictionaryForIdentifier:identifier type:type entity:entity ];
    if (!subscriptions) {
        subscriptions = [NSMutableArray new];
    }
    [subscriptions addObject:requestParameters];
}

- (NSDictionary *)subscriptionDictionaryForIdentifier:(NSString *)identifier type:(NSString *)type entity:(NSDictionary *)entity
{
    if (!identifier || identifier.length < 1) {
        return nil;
    }
    
    if (!entity || entity.count < 1) {
        return nil;
    }
    
    return @{kJCSocketManagerSubscriptionIdKey: identifier,
             kJCSocketManagerSubscriptionTypeKey: type,
             kJCSocketManagerSubscriptionEntityKey: entity};
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
    NSString *type = [results stringValueForKey:kJCSocketManagerEventTypeKey];
    
    // Get the event message data.
    NSDictionary *data = nil;
    id object = [results objectForKey:kJCSocketManagerEventDataKey];
    if (object && [object isKindOfClass:[NSDictionary class]]) {
        data = (NSDictionary *)object;
        }
    [self receivedResult:results type:type data:data];
}

-(void)receivedResult:(NSDictionary *)result type:(NSString *)type data:(NSDictionary *)data
{
    
}

@end
