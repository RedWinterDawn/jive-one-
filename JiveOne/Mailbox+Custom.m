//
//  Mailbox+Custom.m
//  JiveOne
//
//  Created by Daniel George on 6/26/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "Mailbox+Custom.h"

@implementation Mailbox (Custom)

+ (void)addMailboxes:(NSArray*)mailboxes pbxUrl:(NSString *)pbxUrl completed:(void (^)(BOOL suceeded))completed
{
    
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {

        for (NSDictionary *mailboxExtension in mailboxes)
        {
            [self addMailbox:mailboxExtension pbxUrl:pbxUrl withManagedContext:localContext sender:self];
        }
        
        
    } completion:^(BOOL success, NSError *error) {
        completed(success);
    }];

}

+ (Mailbox *)addMailbox:(NSDictionary *)mailboxExtension pbxUrl:(NSString *)pbxUrl withManagedContext:(NSManagedObjectContext *)context sender:(id)sender
{
    NSString *jrn = mailboxExtension[@"jrn"];
    
    Mailbox *newBox = [Mailbox MR_findFirstByAttribute:@"jrn" withValue:jrn];
    
    if (!newBox) {
        newBox = [Mailbox MR_createInContext:context];
        newBox.extensionName = mailboxExtension[@"extensionName"];
        newBox.extensionNumber = mailboxExtension[@"extensionNumber"];
        newBox.jrn = mailboxExtension[@"self_mailbox"];
        newBox.url_self_mailbox = mailboxExtension[@"self_mailbox"];
        newBox.url_pbx = pbxUrl;
    }
    
    return newBox;
}

@end
