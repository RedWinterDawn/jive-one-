//
//  Mailbox+Custom.h
//  JiveOne
//
//  Created by Daniel George on 6/26/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "Mailbox.h"

@interface Mailbox (Custom)
+ (void)addMailboxes:(NSDictionary*)mailbox completed:(void (^)(BOOL suceeded))completed;

@end
