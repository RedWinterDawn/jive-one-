//
//  JCPresenceManager.m
//  JiveOne
//
//  Created by Robert Barclay on 12/23/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCPresenceManager.h"

#import "JCV5ApiClient.h"

#import "JCSocket.h"


@interface JCPresenceManager ()
{
    NSMutableArray *_lines;
    JCSocket *_socket;
}

@end

@implementation JCPresenceManager

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

-(void)subscribeToPbx:(PBX *)pbx
{
    // Create a line presence object to represent the contact.
    NSSet *contacts = pbx.contacts;
    _lines = [NSMutableArray arrayWithCapacity:contacts.count];
    for (Contact *contact in contacts) {
        [_lines addObject:[[JCLinePresence alloc] initWithLineIdentifer:contact.jrn]];
        [JCSocket subscribeToSocketEventsWithIdentifer:contact.jrn entity:contact.jrn type:@"dialog"];
    }
}

-(JCLinePresence *)linePresenceForContact:(Contact *)contact
{
    return [self linePresenceForIdentifier:contact.jrn];
}

-(JCLinePresence *)linePresenceForIdentifier:(NSString *)identifier
{
    if (!_lines) {
        return nil;
    }
    
    for (JCLinePresence *linePresence in _lines) {
        if ([linePresence.identfier isEqualToString:identifier]) {
            return linePresence;
        }
    }
    return nil;
}

#pragma mark - Notification Handlers -

NSString *const kJCPresenceManagerTypeKey       = @"type";
NSString *const kJCPresenceManagerTypeWithdraw  = @"withdraw";
NSString *const kJCPresenceManagerTypeConfirmed = @"confirmed";
NSString *const kJCPresenceManagerDataKey       = @"data";
NSString *const kJCPresenceManagerStateKey      = @"state";
NSString *const kJCPresenceManagerIdentifierKey = @"subId";

-(void)socketDidReceiveMessageSelector:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    NSDictionary *results = [userInfo objectForKey:kJCSocketNotificationResultKey];
    if (!results) {
        NSError *error = [userInfo objectForKey:kJCSocketNotificationErrorKey];
        NSLog(@"%@", [error description]);
        return;
    }
    
    // Right now we only care about withdraws and confirms
    NSString *type = [results stringValueForKey:kJCPresenceManagerTypeKey];
    if (!type || !([type isEqualToString:kJCPresenceManagerTypeWithdraw] || [type isEqualToString:kJCPresenceManagerTypeConfirmed])) {
        return;
    }
    
    NSString *identifier = [results stringValueForKey:kJCPresenceManagerIdentifierKey];
    if (!identifier || identifier.length < 1) {
        return;
    }
    
    JCLinePresence *linePresence = [self linePresenceForIdentifier:identifier];
    if (!linePresence) {
        return;
    }
    
    id object = [results objectForKey:kJCPresenceManagerDataKey];
    if (!object || ![object isKindOfClass:[NSDictionary class]]) {
        return;
    }
    
    NSDictionary *data = (NSDictionary *)object;
    NSString *state = [data stringValueForKey:kJCPresenceManagerStateKey];
    if (state && [state isEqualToString:kJCPresenceManagerTypeConfirmed]) {
        linePresence.state = JCLinePresenceTypeDoNotDisturb;
    }
    else if (type && [type isEqualToString:kJCPresenceManagerTypeWithdraw]) {
        linePresence.state = JCLinePresenceTypeAvailable;
    }
}

@end


@implementation JCPresenceManager (Singleton)

+(instancetype)sharedManager
{
    static JCPresenceManager *presenceManagerSingleton = nil;
    static dispatch_once_t presenceManagerLoaded;
    dispatch_once(&presenceManagerLoaded, ^{
        presenceManagerSingleton = [[JCPresenceManager alloc] init];
    });
    return presenceManagerSingleton;
}

+ (id)copyWithZone:(NSZone *)zone
{
    return self;
}

+ (void)subscribeToPbx:(PBX *)pbx
{
    [[JCPresenceManager sharedManager] subscribeToPbx:pbx];
}



@end