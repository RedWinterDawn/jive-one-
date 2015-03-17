//
//  JCVoicemailManager.m
//  JiveOne
//
//  Created by Robert Barclay on 3/16/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCVoicemailManager.h"
#import "JCSocket.h"

@interface JCVoicemailManager ()
{
    JCSocket *_socket;
}

@end

@implementation JCVoicemailManager

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

-(void)subscribeToLine:(Line *)line
{
    [JCSocket subscribeToSocketEventsWithIdentifer:line.mailboxJrn entity:line.mailboxJrn type:kJCVoicemailManagerTypeMailbox];
}

NSString *const kJCVoicemailManagerTypeKey       = @"type";
NSString *const kJCVoicemailManagerTypeAnnounce  = @"announce";
NSString *const kJCVoicemailManagerTypeMailbox   = @"mailbox";


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
    NSString *type = [results stringValueForKey:kJCVoicemailManagerTypeKey];
    NSLog(@"%@ %@", type, results);
    
    
    
    
    NSString *state = nil;
    id object = [results objectForKey:kJCPresenceManagerDataKey];
    if (object && [object isKindOfClass:[NSDictionary class]]) {
        NSDictionary *data = (NSDictionary *)object;
        state = [data stringValueForKey:kJCPresenceManagerStateKey];
    }
//
//    if (![type isEqualToString:kJCPresenceManagerTypeWithdraw] && !(state && [state isEqualToString:kJCPresenceManagerTypeConfirmed])) {
//        return;
//    }
//    
//    // Get identifer.
//    NSString *identifier = [results stringValueForKey:kJCPresenceManagerIdentifierKey];
//    if (!identifier || identifier.length < 1) {
//        return;
//    }
//    
//    JCLinePresence *linePresence = [self linePresenceForIdentifier:identifier];
//    if (!linePresence) {
//        return;
//    }
//    
//    if ([type isEqualToString:kJCPresenceManagerTypeWithdraw]) {
//        linePresence.state = JCLinePresenceTypeAvailable;
//    }
//    else if ([state isEqualToString:kJCPresenceManagerTypeConfirmed]) {
//        linePresence.state = JCLinePresenceTypeDoNotDisturb;
//    }
}

@end


@implementation JCVoicemailManager (Singleton)

+(instancetype)sharedManager
{
    static JCVoicemailManager *voicemailManagerSingleton = nil;
    static dispatch_once_t voicemailManagerLoaded;
    dispatch_once(&voicemailManagerLoaded, ^{
        voicemailManagerSingleton = [JCVoicemailManager new];
    });
    return voicemailManagerSingleton;
}

+ (id)copyWithZone:(NSZone *)zone
{
    return self;
}

+ (void)subscribeToLine:(Line *)line
{
    [[JCVoicemailManager sharedManager] subscribeToLine:line];
}

@end