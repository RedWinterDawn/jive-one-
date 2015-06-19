//
//  SMSMessage.m
//  JiveOne
//
//  Created by Robert Barclay on 1/12/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "SMSMessage.h"

#import "DID.h"
#import "PhoneNumber.h"

#import "NSManagedObject+Additions.h"

NSString *const kSMSMessageInboundAttributeKey = @"inbound";

@implementation SMSMessage

#pragma mark - Attributes -

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

@end
