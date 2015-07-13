//
//  JCVoicemailManager.m
//  JiveOne
//
//  Created by Robert Barclay on 3/16/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCVoicemailManager.h"
#import "PBX.h"
#import "Line.h"
#import "Voicemail+V5Client.h"

NSString *const kJCVoicemailManagerTypeKey              = @"type";
NSString *const kJCVoicemailManagerTypeAnnounceValue    = @"announce";
NSString *const kJCVoicemailManagerTypeVoiceMailKey     = @"voicemail";
NSString *const kJCVoicemailManagerSubscriptionTypeKey  = @"mailbox";
NSString *const kJCVoicemailManagerEntityTypeKey        = @"entityType";
NSString *const kJCVoicemailManagerMailboxJrnKey        = @"mailboxJrn";
NSString *const kJCVoicemailManagerActionKey            = @"action";
NSString *const kJCVoicemailManagerActionValue          = @"NEW";

@implementation JCVoicemailManager

+ (void)generateSubscriptionForLine:(Line *)line
{
    if (!line.pbx.v5) {
        return;
    }
    
    [[JCVoicemailManager sharedManager] generateSubscriptionForLine:line];
}

#pragma mark - Private -

-(void)generateSubscriptionForLine:(Line *)line
{
    [self generateSubscriptionWithIdentifier:line.mailboxId
                                        type:kJCVoicemailManagerTypeVoiceMailKey
                            subscriptionType:kJCVoicemailManagerSubscriptionTypeKey
                                         pbx:line.pbx];
}

-(void)receivedResult:(NSDictionary *)result type:(NSString *)type data:(NSDictionary *)data {
 
    // We are only looking for voicemail anounce events.
    if (![type isEqualToString:kJCVoicemailManagerTypeAnnounceValue]) {
        return;
    }
    
    // We require the data to be set.
    if (!data) {
        return;
    }
    
    // We only care about voicemail entity types. (What we registered for).
    NSDictionary *entityTypeData = [data dictionaryForKey:kJCVoicemailManagerEntityTypeKey];
    NSString *entityType = [entityTypeData valueForKey:kJCVoicemailManagerEntityTypeKey];
    if (![entityType isEqualToString:kJCVoicemailManagerSubscriptionTypeKey]) {
        return;
    }
    
    NSDictionary *actionData = [data dictionaryForKey:kJCVoicemailManagerActionKey];
    NSString *action = [actionData stringValueForKey:kJCVoicemailManagerActionKey];
    if ([action isEqualToString:kJCVoicemailManagerActionValue]) {
        return;
    }
    
    NSString *mailboxJrn = [data stringValueForKey:kJCVoicemailManagerMailboxJrnKey];
    Line *line = [Line MR_findFirstByAttribute:NSStringFromSelector(@selector(mailboxJrn)) withValue:mailboxJrn];
    [Voicemail downloadVoicemailsForLine:line completion:NULL];
    
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