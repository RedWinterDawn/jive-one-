//
//  ContactGroup.m
//  JiveOne
//
//  Created by Robert Barclay on 6/22/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "ContactGroup.h"
#import "Contact.h"

#import "NSManagedObject+Additions.h"

NSString *const kContactGroupMarkForUpdateAttribute = @"markForUpdate";
NSString *const kContactGroupMarkForDeletionAttribute = @"markForDeletion";

@implementation ContactGroup

-(void)setMarkForUpdate:(BOOL)markForUpdate
{
    [self setPrimitiveValueFromBoolValue:markForUpdate forKey:kContactGroupMarkForUpdateAttribute];
}

-(BOOL)isMarkedForUpdate
{
    return [self boolValueFromPrimitiveValueForKey:kContactGroupMarkForUpdateAttribute];
}

-(void)setMarkForDeletion:(BOOL)markForDeletion
{
    [self setPrimitiveValueFromBoolValue:markForDeletion forKey:kContactGroupMarkForDeletionAttribute];
}

-(BOOL)isMarkedForDeletion
{
    return [self boolValueFromPrimitiveValueForKey:kContactGroupMarkForDeletionAttribute];
}

-(void)setEtag:(NSInteger)etag
{
    [self setPrimitiveValueFromIntegerValue:etag forKey:NSStringFromSelector(@selector(etag))];
}

-(NSInteger)etag
{
    return [self integerValueFromPrimitiveValueForKey:NSStringFromSelector(@selector(etag))];
}

@dynamic contacts;
@dynamic user;

-(NSSet *)members
{
    return self.contacts;
}

-(NSString *)sectionName
{
    return NSLocalizedString(@"My Jive", @"My Jive Groups");
}

@end
