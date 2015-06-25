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

+ (void)syncContactGroupsForUser:(User *)user completion:(CompletionHandler)completion
{
    [self deleteMarkedContactGroupsForUser:user completion:^(BOOL success, NSError *error) {
        if (success) {
            [self uploadMarkedContactsForUser:user completion:^(BOOL success, NSError *error) {
                if (success) {
                    [self downloadContactGroupsForUser:user completion:completion];
                } else {
                    if (completion) {
                        completion(NO, error);
                    }
                }
            }];
        } else {
            if (completion) {
                completion(NO, error);
            }
        }
    }];
}

+ (void)syncContactGroup:(ContactGroup *)contact completion:(CompletionHandler)completion
{
    // if we have a pending upload, do the update rather than a download. We will be updated to be
    // the latest version.
    if (contact.isMarkedForUpdate) {
        [self uploadContactGroup:contact completion:completion];
        return;
    }
    
    [self downloadContactGroup:contact completion:completion];
}

#pragma mark - Download -

+ (void)downloadContactGroupsForUser:(User *)user completion:(CompletionHandler)completion
{
    [JCV5ApiClient downloadContactGroupsWithCompletion:^(BOOL success, id response, NSError *error) {
        if (success) {
            //[self processContactsDownloadResponse:response user:user completion:completion];
            
            // TODO: Need Server implementation to complete.
            
            if (completion) {
                completion(YES, nil);
            }
            
        } else {
            if (completion) {
                completion(NO, error);
            }
        }
    }];
}

+ (void)downloadContactGroup:(ContactGroup *)contact completion:(CompletionHandler)completion {
    // TODO Need Server implementation to complete.
    
    if (completion) {
        completion(YES, nil);
    }
}


#pragma mark - Upload -

-(void)markForUpdate:(CompletionHandler)completion
{
    self.markForUpdate = TRUE;
    [self.managedObjectContext MR_saveToPersistentStoreWithCompletion:^(BOOL contextDidSave, NSError *error) {
        if(!error) {
            [[self class] uploadContactGroup:self completion:completion];
        } else {
            if (completion) {
                completion(contextDidSave, error);
            }
        }
    }];
}

#pragma mark Private

+ (void)uploadMarkedContactsForUser:(User *)user completion:(CompletionHandler)completion
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"markForUpdate = %@ AND user = %@", @YES, user];
    __block NSMutableArray *pendingGroupsToUpdate = [Contact MR_findAllWithPredicate:predicate inContext:user.managedObjectContext].mutableCopy;
    
    // If we do not have any to delete, call completion.
    if (pendingGroupsToUpdate.count == 0) {
        if (completion) {
            completion(YES, nil);
        }
        return;
    }
    
    // Iterate through each contact to delete.
    __block NSError *batchError;
    for (ContactGroup *group in pendingGroupsToUpdate) {
        [self uploadContactGroup:group completion:^(BOOL success, NSError *error) {
            if (error && !batchError) {
                batchError = error;
            }
            
            [pendingGroupsToUpdate removeObject:group];
            if (pendingGroupsToUpdate.count == 0) {
                if (completion) {
                    completion((batchError == nil), batchError );
                }
            }
        }];
    }
}

+ (void)uploadContactGroup:(ContactGroup *)group completion:(CompletionHandler)completion
{
    [JCV5ApiClient uploadContactGroup:group completion:^(BOOL success, id response, NSError *error) {
        if (success) {
            
            // If we do not get a response, we had a fatal error, so we call completion with an error.
            if (!response) {
                if (completion) {
                    completion(NO, [JCApiClientError errorWithCode:API_CLIENT_RESPONSE_ERROR reason:NSLocalizedString(@"Upload Error", @"Upload Error")  underlyingError:error]);
                }
                return;
            }
            
            if (![response isKindOfClass:[NSDictionary class]]) {
                if (completion) {
                    completion(NO, [JCApiClientError errorWithCode:API_CLIENT_RESPONSE_ERROR reason:NSLocalizedString(@"Upload Unexpected Server Response", @"Upload Error") underlyingError:error]);
                }
                return;
            }
            
            NSDictionary *contactData = (NSDictionary *)response;
            
            [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
                ContactGroup *localContactGroup = (ContactGroup *)[localContext objectWithID:group.objectID];
                localContactGroup.groupId = [contactData stringValueForKey:kContactGroupIdKey];
                localContactGroup.markForUpdate = TRUE;
            } completion:^(BOOL contextDidSave, NSError *error) {
                if (completion) {
                    completion((error == nil), error);
                }
            }];
        } else {
            if (completion) {
                completion(NO, error);
            }
        }
        
    }];
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
