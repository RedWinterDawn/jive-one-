//
//  BlockedContact.m
//  JiveOne
//
//  Created by Robert Barclay on 4/27/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "BlockedContact.h"

// Managed Objects
#import "DID.h"
#import "LocalContact.h"
#import "NSManagedObject+Additions.h"

NSString *const kBlockedContactMarkForDeletionAttribute = @"markForDeletion";
NSString *const kBlockedContactPendingUploadAttribute = @"pendingUpload";

@implementation BlockedContact

#pragma mark - Attributes -

-(void)setMarkForDeletion:(BOOL)markForDeletion
{
    [self setPrimitiveValueFromBoolValue:markForDeletion forKey:kBlockedContactMarkForDeletionAttribute];
}

-(BOOL)markForDeletion
{
    return [self boolValueFromPrimitiveValueForKey:kBlockedContactMarkForDeletionAttribute];
}

-(void)setPendingUpload:(BOOL)pendingUpload
{
    [self setPrimitiveValueFromBoolValue:pendingUpload forKey:kBlockedContactPendingUploadAttribute];
}

-(BOOL)pendingUpload
{
    return [self boolValueFromPrimitiveValueForKey:kBlockedContactPendingUploadAttribute];
}

#pragma mark - Relationships -

@dynamic did;

@end
