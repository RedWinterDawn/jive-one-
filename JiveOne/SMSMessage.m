//
//  SMSMessage.m
//  JiveOne
//
//  Created by Robert Barclay on 1/12/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "SMSMessage.h"

#import "PBX.h"
#import "DID.h"
#import "PhoneNumber.h"

#import "NSManagedObject+Additions.h"

NSString *const kSMSMessageInboundAttributeKey = @"inbound";

@implementation SMSMessage

#pragma mark - Attributes -

-(void)willSave
{
    if (![self isDeleted])
    {
        // generates the t9 representation of the name of the number.
        NSString *pbxId = self.did.pbx.pbxId;
        if(pbxId) {
            [self setPrimitiveValue:pbxId forKey:NSStringFromSelector(@selector(pbxId))];
        }
    }
    [super willSave];
}

-(void)setInbound:(BOOL)inbound
{
    [self setPrimitiveValueFromBoolValue:inbound forKey:kSMSMessageInboundAttributeKey];
}

-(BOOL)isInbound
{
    return [self boolValueFromPrimitiveValueForKey:kSMSMessageInboundAttributeKey];
}

#pragma mark - Relationships -

@dynamic did;
@dynamic phoneNumber;

#pragma mark - Transient Properties -

-(NSString *)senderId
{
    if (self.isInbound) {
        return self.phoneNumber.number;
    }
    return self.did.number;
}

-(NSString *)senderDisplayName
{
    if (self.isInbound) {
        return self.phoneNumber.name;
    }
    return NSLocalizedString(@"me", nil);
}

-(NSString *)detailText {
    return [NSString stringWithFormat:NSLocalizedString(@"SMS on %@", nil), super.detailText];
}

#pragma mark - Helper Properties -

-(void)setDidId:(NSString *)didId
{
    DID *did = [DID MR_findFirstByAttribute:NSStringFromSelector(@selector(didId))
                                  withValue:didId
                                  inContext:self.managedObjectContext];
    if (did && self.did != did) {
        self.did = did;
    }
}

-(void)setNumber:(NSString *)number name:(NSString *)name
{
    self.messageGroupId = number;
    PhoneNumber *phoneNumber = [PhoneNumber MR_findFirstByAttribute:NSStringFromSelector(@selector(number))
                                                             withValue:number
                                                             inContext:self.managedObjectContext];
    
    if (!phoneNumber) {
        phoneNumber = [PhoneNumber MR_createEntityInContext:self.managedObjectContext];
        phoneNumber.number = number;
        if (name) {
            phoneNumber.name = name;
        }
    }
    
    if (self.phoneNumber != phoneNumber) {
        self.phoneNumber = phoneNumber;
    }
}

+(void)markSMSMessagesWithGroupIdForDeletion:(NSString *)groupId pbx:(PBX *)pbx completion:(CompletionHandler)completion
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"messageGroupId = %@ && did.pbx = %@", groupId, pbx];
    NSArray *messages = [SMSMessage MR_findAllWithPredicate:predicate inContext:pbx.managedObjectContext];
    
    NSMutableArray *remainingMessages = [NSMutableArray arrayWithArray:messages];
    for (SMSMessage *message in messages) {
        [message markForDeletion:^(BOOL success, NSError *error) {
            [remainingMessages removeObject:message];
            if (remainingMessages.count == 0) {
                if (completion) {
                    completion(YES, nil);
                }
            }
        }];
    }
}

+(void)markSMSMessagesWithGroupIdAsRead:(NSString *)groupId pbx:(PBX *)pbx completion:(CompletionHandler)completion
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"messageGroupId = %@ && did.pbx = %@", groupId, pbx];
    NSArray *messages = [SMSMessage MR_findAllWithPredicate:predicate inContext:pbx.managedObjectContext];
    
    NSMutableArray *remainingMessages = [NSMutableArray arrayWithArray:messages];
    for (SMSMessage *message in messages) {
        [message markAsRead:^(BOOL success, NSError *error) {
            [remainingMessages removeObject:message];
            if (remainingMessages.count == 0) {
                if (completion) {
                    completion(YES, nil);
                }
            }
        }];
    }
}

@end
