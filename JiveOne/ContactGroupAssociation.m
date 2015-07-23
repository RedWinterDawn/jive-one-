//
//  ContactGroupAssociation.m
//  JiveOne
//
//  Created by Robert Barclay on 6/24/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "ContactGroupAssociation.h"
#import "Contact.h"
#import "ContactGroup.h"
#import "NSManagedObject+Additions.h"

NSString *const kContactGroupAssociationMarkForDeletionAttribute = @"markForDeletion";
NSString *const kContactGroupAssociationMarkForUpdateAttribute = @"markForUpdate";

@implementation ContactGroupAssociation

-(void)setMarkForDeletion:(BOOL)markForDeletion
{
    [self setPrimitiveValueFromBoolValue:markForDeletion forKey:kContactGroupAssociationMarkForDeletionAttribute];
}

-(BOOL)isMarkedForDeletion
{
    return [self boolValueFromPrimitiveValueForKey:kContactGroupAssociationMarkForDeletionAttribute];
}

-(void)setMarkForUpdate:(BOOL)markForUpdate
{
    [self setPrimitiveValueFromBoolValue:markForUpdate forKey:kContactGroupAssociationMarkForUpdateAttribute];
}

-(BOOL)isMarkedForUpdate
{
    return [self boolValueFromPrimitiveValueForKey:kContactGroupAssociationMarkForUpdateAttribute];
}

@dynamic group;
@dynamic contact;

@end
