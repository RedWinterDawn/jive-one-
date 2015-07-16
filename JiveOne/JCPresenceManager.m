//
//  JCPresenceManager.m
//  JiveOne
//
//  Created by Robert Barclay on 12/23/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCPresenceManager.h"
#import "JCSocket.h"
#import "JCAppSettings.h"
#import "Line.h"


NSString *const kJCPresenceManagerLinesChangedNotification = @"linesChanged";

NSString *const kJCPresenceManagerTypeWithdraw      = @"withdraw";
NSString *const kJCPresenceManagerStateConfirmed    = @"confirmed";
NSString *const kJCPresenceManagerStateKey          = @"state";
NSString *const kJCPresenceManagerIdentifierKey     = @"subId";


@interface JCPresenceManager ()
{
    NSMutableArray *_extensions;
    PBX *_pbx;
}

@end

@implementation JCPresenceManager

-(JCLinePresence *)linePresenceForExtension:(Extension *)extension
{
    return [self linePresenceForIdentifier:extension.extensionId];
}

-(JCLinePresence *)linePresenceForIdentifier:(NSString *)identifier
{
    if (!_extensions) {
        return nil;
    }
    
    for (JCLinePresence *linePresence in _extensions) {
        if ([linePresence.identfier isEqualToString:identifier]) {
            return linePresence;
        }
    }
    return nil;
}

+ (void)generateSubscriptionForPbx:(PBX *)pbx
{
    if (!pbx.v5) {
        return;
    }
    
    [[JCPresenceManager sharedManager] generateSubscriptionForPbx:pbx];
}

#pragma mark - Public Overides -

-(void)receivedResult:(NSDictionary *)result type:(NSString *)type data:(NSDictionary *)data {
    
    NSString *state = [data stringValueForKey:kJCPresenceManagerStateKey];
    if (![type isEqualToString:kJCPresenceManagerTypeWithdraw] && !(state && [state isEqualToString:kJCPresenceManagerStateConfirmed])) {
        return;
    }
    
    // Get identifer.
    NSString *identifier = [result stringValueForKey:kJCPresenceManagerIdentifierKey];
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
    else if ([state isEqualToString:kJCPresenceManagerStateConfirmed]) {
        linePresence.state = JCLinePresenceTypeDoNotDisturb;
    }
}

#pragma mark - Private

NSString *const kJCSocketPreasenceIdentifierKey = @"id";
NSString *const kJCSocketPreasenceAccountKey     = @"account";
NSString *const kJCSocketPreasenceTypeKey       = @"type";
/**
 * Loops through the PBX's contacts and subscribe to presence events for each of them. Creates a 
 * line presence object to represent that contact.
 */
-(void)generateSubscriptionForPbx:(PBX *)pbx
{
    _pbx = pbx;
    
    if (!_pbx) {
        return;
    }
    
    NSSet *extensions = pbx.extensions;
    for (Extension *extension in extensions){
        [_extensions addObject:[[JCLinePresence alloc] initWithLineIdentifer:extension.extensionId]];
        [self generateSubscriptionWithIdentifier:extension.extensionId
                                            type:@"line"
                                subscriptionType:@"registration"
                                             pbx:pbx];
    }
    [self postNotificationNamed:kJCPresenceManagerLinesChangedNotification];
}

-(void)unsubscribeFromPbx:(PBX *)pbx
{
    [JCSocket unsubscribeToSocketEvents:^(BOOL success, NSError *error) {
        if (success) {
            _extensions = nil;
            [self postNotificationNamed:kJCPresenceManagerLinesChangedNotification];
        }
    }];
}

@end