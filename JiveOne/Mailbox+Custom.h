//
//  Mailbox+Custom.h
//  JiveOne
//
//  Created by Daniel George on 6/26/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "Mailbox.h"

@interface Mailbox (Custom)
+ (void)addMailboxes:(NSDictionary*)mailbox pbxUrl:(NSString *)pbxUrl completed:(void (^)(BOOL suceeded))completed;
+ (Mailbox *)addMailbox:(NSDictionary *)mailbox pbxUrl:(NSString *)pbxUrl withManagedContext:(NSManagedObjectContext *)context sender:(id)sender;

@end
