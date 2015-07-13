//
//  JCPresenceManager.h
//  JiveOne
//
//  Created by Robert Barclay on 12/23/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

@import Foundation;

#import "JCSocketManager.h"
#import "JCLinePresence.h"
#import "PBX.h"
#import "InternalExtension.h"

extern NSString *const kJCPresenceManagerLinesChangedNotification;

@interface JCPresenceManager : JCSocketManager

-(JCLinePresence *)linePresenceForContact:(InternalExtension *)contact;
-(JCLinePresence *)linePresenceForIdentifier:(NSString *)identifier;

+(void)generateSubscriptionForPbx:(PBX *)pbx;
+(void)unsubscribeFromPbx:(PBX *)pbx;

@end
