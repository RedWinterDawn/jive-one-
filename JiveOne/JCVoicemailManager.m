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

-(void)receivedResult:(NSDictionary *)result type:(NSString *)type data:(NSDictionary *)data {
   
    NSLog(@"***   ***   ***   ***   ***   ***   ***   ***   ***   ***   ***   ***   ***   ***Here is your type and result :%@ %@", type, result);
//        announce {
//    data =     {
//        action =         {
//            action = NEW;
//        };
//        alert =         {
//            alert = "New voicemail from George's Desk <6667>";
//        };
//        entityType =         {
//            entityType = mailbox;
//        };
//        mailboxJrn = "jrn:voicemail::jive:01471162-f384-24f5-9351-000100420005:vmbox/014b17d6-0d5a-3d74-1cb7-000100620005";
//        self = "https://api.jive.com/voicemail/v1/mailbox/id/014b17d6-0d5a-3d74-1cb7-000100620005";
//        voicemailCount =         {
//            INBOX = 1;
//            total = 1;
//        };
//    };
//    entityId = 1;
//    subId = "jrn:voicemail::jive:01471162-f384-24f5-9351-000100420005:vmbox/014b17d6-0d5a-3d74-1cb7-000100620005";
//    type = announce;
//}
}

@end