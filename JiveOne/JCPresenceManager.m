//
//  JCPresenceManager.m
//  JiveOne
//
//  Created by Robert Barclay on 12/23/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCPresenceManager.h"
#import "JCSocket.h"
#import "Extension.h"
#import "PBX.h"

NSString *const kJCPresenceManagerLinesChangedNotification = @"linesChanged";

NSString *const kJCPresenceManagerEntityType        = @"line";
NSString *const kJCPresenceManagerSubscriptionType  = @"registration";



NSString *const kJCPresenceManagerTypeWithdraw      = @"withdraw";
NSString *const kJCPresenceManagerStateConfirmed    = @"confirmed";
NSString *const kJCPresenceManagerStateKey          = @"state";
NSString *const kJCPresenceManagerIdentifierKey     = @"subId";


@interface JCPresenceManager ()
{
    NSMutableArray *_extensions;
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

-(void)receivedResult:(NSDictionary *)result type:(NSString *)type data:(NSDictionary *)data
{
    NSLog(@"%@", [result description]);
    
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


/**
 * Loops through the PBX's contacts and subscribe to presence events for each of them. Creates a 
 * line presence object to represent that contact.
 */
-(void)generateSubscriptionForPbx:(PBX *)pbx
{
    if (self.appSettings.isPresenceEnabled)
    {
        _extensions = [NSMutableArray new];
        NSSet *extensions = pbx.extensions;
        for (Extension *extension in extensions){
            [_extensions addObject:[[JCLinePresence alloc] initWithLineIdentifer:extension.extensionId]];
            
            [self generateSubscriptionWithIdentifier:extension.extensionId
                                                type:kJCPresenceManagerSubscriptionType
                                          entityType:kJCPresenceManagerEntityType
                                            entityId:extension.extensionId
                                     entityAccountId:pbx.pbxId];
        }
    }
    else {
        _extensions = nil;
    }
    
    [self postNotificationNamed:kJCPresenceManagerLinesChangedNotification];
}

@end