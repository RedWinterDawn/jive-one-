//
//  JCPresenceManager.h
//  JiveOne
//
//  Created by Robert Barclay on 12/23/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

@import Foundation;

#import "JCLinePresence.h"
#import "PBX.h"
#import "Contact.h"

extern NSString *const kJCPresenceManagerLinesChangedNotification;

@interface JCPresenceManager : NSObject

-(JCLinePresence *)linePresenceForContact:(Contact *)contact;
-(JCLinePresence *)linePresenceForIdentifier:(NSString *)identifier;

@end

@interface JCPresenceManager (Singleton)

+(instancetype)sharedManager;
+(void)subscribeToPbx:(PBX *)pbx;
+(void)unsubscribeFromPbx:(PBX *)pbx;

@end
