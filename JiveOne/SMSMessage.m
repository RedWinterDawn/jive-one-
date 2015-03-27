//
//  SMSMessage.m
//  JiveOne
//
//  Created by Robert Barclay on 1/12/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "SMSMessage.h"

#import "DID.h"
#import "LocalContact.h"

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
@dynamic localContact;

#pragma mark - Transient Properties -

-(NSString *)senderId
{
    if (self.isInbound) {
        return self.localContact.number;
    }
    return self.did.number;
}

-(NSString *)senderDisplayName
{
    if (self.isInbound) {
        return self.localContact.name;
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
    
    LocalContact *localContact = [LocalContact MR_findFirstByAttribute:NSStringFromSelector(@selector(number))
                                                             withValue:number
                                                             inContext:self.managedObjectContext];
    
    
    if (!localContact) {
        localContact = [LocalContact MR_createInContext:self.managedObjectContext];
        localContact.number = number;
        if (name) {
            localContact.name = name;
        }
    }
    
    if (self.localContact != localContact) {
        self.localContact = localContact;
    }
}

@end
