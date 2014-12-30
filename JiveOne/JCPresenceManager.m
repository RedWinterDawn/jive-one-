//
//  JCPresenceManager.m
//  JiveOne
//
//  Created by Robert Barclay on 12/23/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCPresenceManager.h"
#import "JCSocket.h"

NSString *const kJCPresenceManagerLinesChangedNotification = @"linesChanged";

@interface JCPresenceManager ()
{
    NSMutableArray *_lines;
    JCSocket *_socket;
}

@end

@implementation JCPresenceManager

/**
 * Override class init to grab pointer to socket singleton, and to register for Notification Center 
 * events from the socket for recieved data.
 */
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

/**
 * Loops through the PBX's contacts and subscribe to presence events for each of them. Creates a 
 * line presence object to represent that contact.
 */
-(void)subscribeToPbx:(PBX *)pbx
{
    // Create a line presence object to represent the contact.
    NSSet *contacts = pbx.contacts;
    _lines = [NSMutableArray arrayWithCapacity:contacts.count];
    for (Contact *contact in contacts) {
        [_lines addObject:[[JCLinePresence alloc] initWithLineIdentifer:contact.jrn]];
        [JCSocket subscribeToSocketEventsWithIdentifer:contact.jrn entity:contact.jrn type:@"dialog"];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kJCPresenceManagerLinesChangedNotification object:self userInfo:nil];
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

    NSString *state = nil;
    id object = [results objectForKey:kJCPresenceManagerDataKey];
    if (object && [object isKindOfClass:[NSDictionary class]]) {
        NSDictionary *data = (NSDictionary *)object;
        state = [data stringValueForKey:kJCPresenceManagerStateKey];
    }
    
    if (![type isEqualToString:kJCPresenceManagerTypeWithdraw] && !(state && [state isEqualToString:kJCPresenceManagerTypeConfirmed])) {
        return;
    }
    
    // Get identifer.
    NSString *identifier = [results stringValueForKey:kJCPresenceManagerIdentifierKey];
    if (!identifier || identifier.length < 1) {
        return;
    }
    
    JCLinePresence *linePresence = [self linePresenceForIdentifier:identifier];
    if (!linePresence) {
        return;
    }
    
    if ([type isEqualToString:kJCPresenceManagerTypeWithdraw]) {
        linePresence.state = JCLinePresenceTypeAvailable;
    }
    else if ([state isEqualToString:kJCPresenceManagerTypeConfirmed]) {
        linePresence.state = JCLinePresenceTypeDoNotDisturb;
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