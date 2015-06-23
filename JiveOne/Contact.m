//
//  Contact.m
//  JiveOne
//
//  Created by Robert Barclay on 6/5/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "Contact.h"
#import "PhoneNumber.h"
#import "JCPhoneNumberDataSourceUtils.h"
#import "NSManagedObject+Additions.h"

NSString *const kContactMarkForDeletionAttribute = @"markForDeletion";
NSString *const kContactMarkForUpdateAttribute = @"markForUpdate";

@implementation Contact

// Attributes

@dynamic contactId;
@dynamic etag;

-(void)setMarkForDeletion:(BOOL)markForDeletion
{
    [self setPrimitiveValueFromBoolValue:markForDeletion forKey:kContactMarkForDeletionAttribute];
}

-(BOOL)isMarkedForDeletion
{
    return [self boolValueFromPrimitiveValueForKey:kContactMarkForDeletionAttribute];
}

-(void)setMarkForUpdate:(BOOL)markForUpdate
{
    [self setPrimitiveValueFromBoolValue:markForUpdate forKey:kContactMarkForUpdateAttribute];
}

-(BOOL)isMarkedForUpdate
{
    return [self boolValueFromPrimitiveValueForKey:kContactMarkForUpdateAttribute];
}

-(void)setEtag:(NSInteger)etag
{
    [self setPrimitiveValueFromIntegerValue:etag forKey:NSStringFromSelector(@selector(etag))];
}

-(NSInteger)etag
{
    return [self integerValueFromPrimitiveValueForKey:NSStringFromSelector(@selector(etag))];
}

// Relationships

@dynamic user;
@dynamic phoneNumbers;
@dynamic info;
@dynamic addresses;
@dynamic contactGroups;

// Overides

-(NSString *)number
{
    NSSet *phoneNumbers = self.phoneNumbers;
    if (phoneNumbers && phoneNumbers.count > 0) {
        PhoneNumber *phoneNumber = phoneNumbers.allObjects.firstObject;
        return phoneNumber.number;
    }
    return nil;
}

@end
