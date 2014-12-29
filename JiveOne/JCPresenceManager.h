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

@interface JCPresenceManager : NSObject

-(JCLinePresence *)linePresenceForContact:(Contact *)contact;

@end

@interface JCPresenceManager (Singleton)

+(instancetype)sharedManager;
+(void)subscribeToPbx:(PBX *)pbx;

@end
