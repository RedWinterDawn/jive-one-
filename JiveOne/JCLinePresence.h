//
//  JCLinePresence.h
//  JiveOne
//
//  Created by Robert Barclay on 12/24/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

@import Foundation;

typedef enum : NSUInteger {
    JCLinePresenceTypeOffline       = 0,
    JCLinePresenceTypeAvailable     = 1,
    JCLinePresenceTypeBusy          = 9,
    JCLinePresenceTypeInvisible     = 4,
    JCLinePresenceTypeDoNotDisturb  = 2,
    JCLinePresenceTypeAway          = 7,
    JCLinePresenceTypeNone          = -1
} JCLinePresenceState;

@interface JCLinePresence : NSObject

-(instancetype)initWithLineIdentifer:(NSString *)identifier;

@property (nonatomic, readonly) NSString *identfier;
@property (nonatomic) JCLinePresenceState state;

@end
