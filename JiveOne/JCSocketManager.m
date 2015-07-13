//
//  JCSocketManager.m
//  JiveOne
//
//  Created by Robert Barclay on 3/17/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCSocketManager.h"
#import "PBX.h"

NSString *const kJCSocketManagerTypeKey = @"type";
NSString *const kJCSocketManagerDataKey = @"entity";

NSString *const kJCSocketManagerTypeKeepAlive = @"keepalive";

NSString *const kJCSocketParameterIdentifierKey = @"id";
NSString *const kJCSocketParameterEntityKey     = @"entity";
NSString *const kJCSocketParameterTypeKey       = @"type";

NSString *const kJCSocketParameterAccountKey    = @"account";


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
    self = [super init];
    if (self) {
        _socket = [JCSocket sharedSocket];
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
    
    [JCSocket unsubscribeToSocketEvents:completion];
}

-(void)subscribe
{
    if (subscriptions) {
        [JCSocket subscribeToSocketEventsWithArray:subscriptions];
    }
}

-(void)generateSubscriptionWithIdentifier:(NSString *)identifier type:(NSString *)type subscriptionType:(NSString *)subscriptionType pbx:(PBX *)pbx
{
    NSDictionary *entity = @{kJCSocketParameterIdentifierKey:identifier,
                             kJCSocketParameterTypeKey:type,
                             kJCSocketParameterAccountKey:pbx.pbxId};
    
    NSDictionary *requestParameters = [self subscriptionDictionaryForIdentifier:identifier entity:entity type:subscriptionType];
    if (!subscriptions) {
        subscriptions = [NSMutableArray new];
    }
    [subscriptions addObject:requestParameters];
}

- (NSDictionary *)subscriptionDictionaryForIdentifier:(NSString *)identifier entity:(NSDictionary *)entity type:(NSString *)type
{
    if (!identifier || identifier.length < 1) {
        return nil;
    }
    
    if (!entity || entity.count < 1) {
        return nil;
    }
    
    NSMutableDictionary *parameters = [@{kJCSocketParameterIdentifierKey: identifier,
                                         kJCSocketParameterEntityKey: entity} mutableCopy];
    
    if (type) {
        [parameters setObject:type forKey:kJCSocketParameterTypeKey];
    }
    
    return parameters;
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
}

-(void)receivedResult:(NSDictionary *)result type:(NSString *)type data:(NSDictionary *)data
{
    
}

@end
