//
//  JCVoicemailManager.m
//  JiveOne
//
//  Created by Robert Barclay on 3/16/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCVoicemailManager.h"
#import "PBX.h"

NSString *const kJCVoicemailManagerTypeKey       = @"type";
NSString *const kJCVoicemailManagerTypeAnnounce  = @"announce";
NSString *const kJCVoicemailManagerTypeMailbox   = @"mailbox";

@implementation JCVoicemailManager

+ (void)subscribeToLine:(Line *)line
{
    if (!line.pbx.v5) {
        return;
    }
    
    [[JCVoicemailManager sharedManager] subscribeToLine:line];
}

#pragma mark - Private -

-(void)subscribeToLine:(Line *)line
{
    [JCSocket subscribeToSocketEventsWithIdentifer:line.mailboxJrn entity:line.mailboxJrn type:kJCVoicemailManagerTypeMailbox];
}

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

//    NSString *state = nil;
//    id object = [results objectForKey:kJCPresenceManagerDataKey];
//    if (object && [object isKindOfClass:[NSDictionary class]]) {
//        NSDictionary *data = (NSDictionary *)object;
//        state = [data stringValueForKey:kJCPresenceManagerStateKey];
//    }
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