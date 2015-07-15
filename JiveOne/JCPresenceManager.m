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

/**
 * Override class init to grab pointer to socket singleton, and to register for Notification Center 
 * events from the socket for recieved data.
 */
-(instancetype)init
{
    self = [super init];
    if (self) {
        [ [JCAppSettings sharedSettings] addObserver:self forKeyPath:kJCAppSettingsPresenceAttribute options:0 context:NULL];
    }
    return self;
}


-(JCLinePresence *)linePresenceForContact:(InternalExtension *)contact
{
    return [self linePresenceForIdentifier:contact.jrn];
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

+(void)unsubscribeFromPbx:(PBX *)pbx
{
    if (!pbx.v5) {
        return;
    }
    
    [[JCPresenceManager sharedManager] unsubscribeFromPbx:pbx];
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

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:kJCAppSettingsPresenceAttribute]) {
        JCAppSettings *settings = (JCAppSettings *)object;
        if([JCSocket sharedSocket].isReady) {
            if (settings.isPresenceEnabled) {
                [self generateSubscriptionForPbx:_pbx];
            } else {
                [self unsubscribeFromPbx:_pbx];
            }
        }
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
    
    if (![JCAppSettings sharedSettings].isPresenceEnabled) {
        return;
    }
    
    NSSet *extensions = pbx.extensions;
    
    
    
    for (Extension *extension in extensions){
    [self generateSubscriptionWithIdentifier:extension.extensionId
                                                          type:@"registration"
                                      subscriptionType:@"device"
                                                          pbx:pbx];
    }
//    for (Extension *extension in extensions) {
//        [_extensions addObject:[[JCLinePresence alloc] initWithLineIdentifer:extension.jrn]];
//        
//        NSDictionary *entity = @{kJCSocketPreasenceIdentifierKey:extension.extensionId,
//                                    kJCSocketPreasenceAccountKey:@"lame",
//                                       kJCSocketPreasenceTypeKey:@"device"};
//        
//        NSDictionary *requestParameters = [self subscriptionDictionaryForIdentifier:extension.extensionId entity:entity type:@"registration"];
//        [preasenceArray addObject:requestParameters];
//    }
    
//    [JCSocket subscribeToSocketEventsWithArray:preasenceArray];
    
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