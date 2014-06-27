//
//  Mailbox+Custom.m
//  JiveOne
//
//  Created by Daniel George on 6/26/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "Mailbox+Custom.h"

@implementation Mailbox (Custom)

+ (void)addMailboxes:(NSDictionary*)responseObject completed:(void (^)(BOOL suceeded))completed
{
    
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        
        for(NSDictionary *pbx in responseObject[@"pbxs"])
        {
            for (NSDictionary *mailboxExtension in pbx[@"extensions"])
            {
                
                NSString *jrn = mailboxExtension[@"jrn"];
                
                Mailbox *newBox = [Mailbox MR_findFirstByAttribute:@"jrn" withValue:jrn];
                
                if (!newBox) {
                    newBox = [Mailbox MR_createInContext:localContext];
                    newBox.extensionName = mailboxExtension[@"extensionName"];
                    newBox.extensionNumber= mailboxExtension[@"extensionNumber"];
                    newBox.jrn = mailboxExtension[@"jrn"];
                    newBox.url_self_mailbox = [mailboxExtension[@"urls"] objectForKey:@"self_mailbox"];
                }
            }
        }
        
    } completion:^(BOOL success, NSError *error) {
        completed(success);
    }];

}

@end
