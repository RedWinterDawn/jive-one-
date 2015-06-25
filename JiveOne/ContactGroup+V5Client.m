//
//  ContactGroup+V5Client.m
//  JiveOne
//
//  Created by Robert Barclay on 6/24/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "ContactGroup+V5Client.h"

#import "Contact.h"
#import "ContactGroup.h"
#import "ContactGroupAssociation.h"
#import "User.h"

#import "JCV5ApiClient.h"

NSString *const kContactGroupIdKey     = @"id";
NSString *const kContactNameKey        = @"name";

@implementation ContactGroup (V5Client)

-(NSDictionary *)serializedData
{
    NSMutableDictionary *data = [NSMutableDictionary new];
    [data setValue:self.groupId forKey:kContactGroupIdKey];
    [data setValue:self.name forKey:kContactNameKey];
    return data;
}

-(void)markForUpdate:(CompletionHandler)completion
{
    
}


#pragma mark - Deletion -

- (void)markForDeletion:(CompletionHandler)completion
{
    self.markForDeletion = TRUE;
    [self.managedObjectContext MR_saveToPersistentStoreWithCompletion:^(BOOL contextDidSave, NSError *error) {
        if (contextDidSave) {
            [[self class] deleteContactGroup:self completion:completion];
        }
        else {
            if (completion) {
                completion(contextDidSave, error);
            }
        }
    }];
}

#pragma mark Private

+ (void)deleteMarkedContactGroupsForUser:(User *)user completion:(CompletionHandler)completion
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"markForDeletion = %@ AND user = %@", @YES, user];
    __block NSMutableArray *pendingContactGroupsToDelete = [ContactGroup MR_findAllWithPredicate:predicate inContext:user.managedObjectContext].mutableCopy;
    
    // If we do not have any to delete, call completion.
    if (pendingContactGroupsToDelete.count == 0) {
        if (completion) {
            completion(YES, nil);
        }
        return;
    }
    
    // Iterate through each contact to delete.
    __block NSError *batchError;
    for (ContactGroup *group in pendingContactGroupsToDelete) {
        [self deleteContactGroup:group completion:^(BOOL success, NSError *error) {
            if (error && !batchError) {
                batchError = error;
            }
            
            [pendingContactGroupsToDelete removeObject:group];
            if (pendingContactGroupsToDelete.count == 0) {
                if (completion) {
                    completion((batchError == nil), batchError );
                }
            }
        }];
    }
}

+ (void)deleteContactGroup:(ContactGroup *)contactGroup completion:(CompletionHandler)completion
{
    [JCV5ApiClient deleteContactGroup:contactGroup completion:^(BOOL success, id response, NSError *error) {
        if (success)
        {
            [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
                [localContext deleteObject:[localContext objectWithID:contactGroup.objectID]];
            } completion:^(BOOL contextDidSave, NSError *error) {
                if (completion) {
                    if (error) {
                        completion(NO, error);
                    } else {
                        completion(YES, nil);
                    }
                }
            }];
        }
        else {
            if (completion) {
                completion(NO, error);
            }
        }
    }];
}


@end
