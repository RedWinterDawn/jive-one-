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
#import "Contact.h"

extern NSString *const kJCPresenceManagerLinesChangedNotification;

@interface JCPresenceManager : JCSocketManager

-(JCLinePresence *)linePresenceForContact:(Contact *)contact;
-(JCLinePresence *)linePresenceForIdentifier:(NSString *)identifier;

+(void)subscribeToPbx:(PBX *)pbx;
+(void)unsubscribeFromPbx:(PBX *)pbx;

@end
