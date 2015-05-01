//
//  JCSMSMessageManager.m
//  JiveOne
//
//  Created by P Leonard on 4/1/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCSMSMessageManager.h"
#import "SMSMessage+V5Client.h"
#import "JCUnknownNumber.h"
#import "PBX.h"

NSString *const kJCSMSMessageManagerTypeKey              = @"type";
NSString *const kJCSMSMessageManagerUID                    = @"UID";
NSString *const kJCSMSMessageManagerFormNumber        = @"fromNumber";

NSString *const kJCSMSMessageManagerEntityTypeKey        = @"entityType";
NSString *const kJCSMSMessageManagerTypeSMSMessageKey       = @"smsmessage";
//NSString *const kJCSMSMessageManagerActionKey            = @"action";
//NSString *const kJCSMSMessageManagerActionValue          = @"NEW";
//NSString *const kJCSMSMessageManagerSMSID          = @"ID";


@implementation JCSMSMessageManager

+(void)subscribeToPbx:(PBX *)pbx {
    [[JCSMSMessageManager sharedManager] subscribeToPbx:pbx];
}

#pragma mark - Private -

-(void)subscribeToPbx:(PBX *)pbx
{
    NSSet *dids = pbx.dids;
    for (DID *did in dids) {
        [self subscribeToDid:did];
    }
}

-(void)subscribeToDid:(DID *)did
{
    if (did.canReceiveSMS) {
        [JCSocket subscribeToSocketEventsWithIdentifer:did.jrn entity:did.jrn type:kJCSMSMessageManagerTypeSMSMessageKey];
    }
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
    JCUnknownNumber *person = [JCUnknownNumber new];
    person.number = fromNumber;
    [SMSMessage downloadMessagesForDID:did toPerson:person completion:NULL];
}

@end
