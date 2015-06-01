//
//  LocalContact.m
//  JiveOne
//
//  Created by Robert Barclay on 2/12/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "LocalContact.h"
#import "NSManagedObject+Additions.h"

static NSString *LocalContactNumberAttributeKey = @"number";
static NSString *LocalContactNameAttributeKey   = @"name";
static NSString *LocalContactPersonIdAttributeKey = @"personId";

@implementation LocalContact

-(void)setNumber:(NSString *)number
{
    [self setPrimitiveValueFromStringValue:number forKey:LocalContactNumberAttributeKey];
}

-(NSString *)number
{
    return [self stringValueFromPrimitiveValueForKey:LocalContactNumberAttributeKey];
}

-(void)setPersonId:(NSInteger)personId
{
    [self setPrimitiveValueFromIntegerValue:personId forKey:LocalContactPersonIdAttributeKey];
}

-(NSInteger)personId
{
    return [self integerValueFromPrimitiveValueForKey:LocalContactPersonIdAttributeKey];
}

@dynamic personHash;
@dynamic smsMessages;
@dynamic lineEvents;

@synthesize phoneNumber;

@end

@implementation LocalContact (JCAddressBook)

+(LocalContact *)localContactForAddressBookNumber:(JCAddressBookNumber *)phoneNumber context:(NSManagedObjectContext *)context
{
    NSNumber *recordId = [NSNumber numberWithInteger:phoneNumber.recordId];
    NSString *hash = phoneNumber.personHash;
    NSString *dialableNumber = phoneNumber.dialableNumber;
    
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"personHash = %@ AND personId = %@ AND number CONTAINS[cd] %@", hash, recordId, dialableNumber];
    
    // Check for the easy find.
    LocalContact *localContact = [LocalContact MR_findFirstWithPredicate:predicate inContext:context];
    if (localContact) {
        localContact.phoneNumber = phoneNumber;
        return localContact;
    }
    
    // If we did not find one, check to see if we have one with the same hash of the object, and try
    // to link to that. The hash is based off the name, so we should be able to link to that if its
    // id has changed in core data. if we find one, update the record id.
    predicate = [NSPredicate predicateWithFormat:@"personHash = %@ AND number CONTAINS[cd] %@", hash, dialableNumber];
    localContact = [LocalContact MR_findFirstWithPredicate:predicate inContext:context];
    if (localContact) {
        localContact.phoneNumber = phoneNumber;
        localContact.personId = phoneNumber.recordId;
        return localContact;
    }
    
    // If we have not found one by the combination of the id, hash and number, we either do not have
    // one, or the record has changed beyond recognition. We cannot trust the id to be the same
    // object, incase the phone was restored, and the number to be unique, so we will create a new
    // local contact to link it too.
    
    localContact = [LocalContact MR_createEntityInContext:context];
    localContact.personId   = phoneNumber.recordId;
    localContact.personHash = hash;
    localContact.name       = phoneNumber.name;
    localContact.firstName  = phoneNumber.firstName;
    localContact.lastName   = phoneNumber.lastName;
    localContact.number     = phoneNumber.dialableNumber;
    return localContact;
}

@end