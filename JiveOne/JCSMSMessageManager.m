//
//  JCSMSMessageManager.m
//  JiveOne
//
//  Created by P Leonard on 4/1/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCSMSMessageManager.h"
#import "SMSMessage+V5Client.h"
#import "PBX.h"
#import "JCMessageGroup.h"
#import "JCPhoneNumber.h"

NSString *const kJCSMSMessageManagerTypeKey                 = @"type";
NSString *const kJCSMSMessageManagerUID                     = @"UID";
NSString *const kJCSMSMessageManagerFormNumber              = @"fromNumber";

NSString *const kJCSMSMessageManagerEntityTypeKey           = @"entityType";
NSString *const kJCSMSMessageManagerTypeSMSMessageKey       = @"smsmessage";
NSString *const kJCSMSMessageManagerEntityDialogKey         = @"dialog";
NSString *const kJCSMSMessageManagerEntityConversationKey   = @"conversation";

@implementation JCSMSMessageManager

+(void)generateSubscriptionForPbx:(PBX *)pbx {
    [[JCSMSMessageManager sharedManager] generateSubscriptionForPbx:pbx];
}

#pragma mark - Private -

-(void)generateSubscriptionForPbx:(PBX *)pbx
{
    NSSet *dids = pbx.dids;
    for (DID *did in dids) {
        [self subscribeToDid:did];
    }
}

-(void)subscribeToDid:(DID *)did
{
    if (!did.canReceiveSMS){
        return;
    }
    
    [self generateSubscriptionWithIdentifier:did.didId
                                        type:kJCSMSMessageManagerEntityConversationKey
                                  entityType:kJCSMSMessageManagerEntityDialogKey
                                    entityId:did.didId entityAccountId:did.pbx.pbxId];
}

-(void)receivedResult:(NSDictionary *)result type:(NSString *)type data:(NSDictionary *)data {
    
    // We are only looking for SMS Messages anounce events.
    if (![type isEqualToString:kJCSMSMessageManagerTypeSMSMessageKey]) {
        return;
    }
    
    // We require the data to be set.
    if (!data) {
        return;
    }
    
    // We only care about SMS mesages entity types. (What we registered for).
    NSDictionary *entityTypeData = [data dictionaryForKey:kJCSMSMessageManagerEntityTypeKey];
    NSString *entityType = [entityTypeData valueForKey:kJCSMSMessageManagerEntityTypeKey];
    if (![entityType isEqualToString:kJCSMSMessageManagerTypeSMSMessageKey]) {
        return;
    }
    
    NSString *didId = [data stringValueForKey:kJCSMSMessageManagerUID];
    DID *did = [DID MR_findFirstByAttribute:NSStringFromSelector(@selector(did)) withValue:didId];
    
    NSString *fromNumber = [data stringValueForKey:@"fromNumber"];
    JCPhoneNumber *phoneNumber = [[JCPhoneNumber alloc] initWithName:nil number:fromNumber];
    JCMessageGroup *messageGroup = [[JCMessageGroup alloc] initWithPhoneNumber:phoneNumber];
    [SMSMessage downloadMessagesForDID:did toMessageGroup:messageGroup completion:NULL];
}

@end
