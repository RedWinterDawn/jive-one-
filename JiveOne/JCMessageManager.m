//
//  JCMessageManager.m
//  JiveOne
//
//  Created by P Leonard on 4/1/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCMessageManager.h"
#import "SMSMessage+V5Client.h"

NSString *const kJCMessageManagerTypeKey              = @"type";
NSString *const kJCMessageManagerEntityTypeKey        = @"entityType";
NSString *const kJCMessageManagerActionKey            = @"action";
NSString *const kJCMessageManagerActionValue          = @"NEW";
NSString *const kJCMessageManagerSMSID          = @"ID";


@implementation JCMessageManager

+(void)subscribeToLine:(Line *)line {
    [[JCMessageManager sharedManager] subscribeToLine:line];
}

#pragma mark - Private -

-(void)subscribeToLine:(Line *)line
{
    [JCSocket subscribeToSocketEventsWithIdentifer:line.jediID entity:line.jediID type:kJCMessageManagerSMSID];
}

-(void)receivedResult:(NSDictionary *)result type:(NSString *)type data:(NSDictionary *)data {
    
    // We are only looking for voicemail anounce events.
    if (![type isEqualToString:kJCMessageManagerActionValue]) {
        return;
    }
    
    // We require the data to be set.
    if (!data) {
        return;
    }
    
    // We only care about voicemail entity types. (What we registered for).
    NSDictionary *entityTypeData = [data dictionaryForKey:kJCMessageManagerEntityTypeKey];
    NSString *entityType = [entityTypeData valueForKey:kJCMessageManagerEntityTypeKey];
    if (![entityType isEqualToString:kJCMessageManagerSMSID]) {
        return;
    }
    
    NSDictionary *actionData = [data dictionaryForKey:kJCMessageManagerActionKey];
    NSString *action = [actionData stringValueForKey:kJCMessageManagerActionKey];
    if ([action isEqualToString:kJCMessageManagerActionValue]) {
        return;
    }
    
    NSString *mailboxJrn = [data stringValueForKey:kJCMessageManagerSMSID];
    Line *line = [Line MR_findFirstByAttribute:NSStringFromSelector(@selector(mailboxJrn)) withValue:mailboxJrn];
    [Message downloadSMSForLine:line completion:NULL];
    
    //    Expected Response
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
