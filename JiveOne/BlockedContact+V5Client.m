//
//  DID+V5Client.m
//  JiveOne
//
//  Created by Robert Barclay on 5/5/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "BlockedContact+V5Client.h"
#import "JCV5ApiClient.h"
#import "DID.h"

@implementation BlockedContact (V5Client)

+(void)downloadBlockedForDIDs:(NSSet *)dids completion:(CompletionHandler)completion
{
    __block NSError *batchError;
    __block NSMutableSet *pendingDids = [NSMutableSet setWithSet:dids];
    for (id object in dids) {
        if ([object isKindOfClass:[DID class]]) {
            __block DID *did = (DID *)object;
            [self downloadBlockedForDID:did completion:^(BOOL success, NSError *error) {
                if (error && !batchError) {
                    batchError = error;
                }
                
                [pendingDids removeObject:did];
                if (pendingDids.count == 0) {
                    if (completion) {
                        completion((error == nil), batchError );
                    }
                }
            }];
        }
    }
}

+(void)blockPendingBlockedContacts
{
    // TODO: do this.
    
//    NSArray *pendingBlockedContacts = [BlockedContact MR_findByAttribute:@"pendingUpload" withValue:@TRUE];
//    if (pendingBlockedContacts.count > 0) {
////        for (<#type *object#> in pendingBlockedContacts) {
////            <#statements#>
////        }
//    }
}


+(void)downloadBlockedForDID:(DID *)did completion:(CompletionHandler)completion
{
    [JCV5ApiClient downloadMessagesBlockedForDID:did completion:^(BOOL success, id response, NSError *error) {
        if (success) {
            [self processBlockedResponseObject:response did:did completion:completion];
        }
        else {
            if (completion) {
                completion(NO, error);
            }
        }
    }];
}

+(void)blockNumber:(id<JCPhoneNumberDataSource>)phoneNumber did:(DID *)did completion:(CompletionHandler)completion;
{
    [JCV5ApiClient blockSMSMessageForDID:did
                                  number:phoneNumber
                              completion:^(BOOL success, id response, NSError *error) {
                                  [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
                                      DID *localDID = (DID *)[localContext objectWithID:did.objectID];
                                      BlockedContact *blockedContact = [self createBlockedMessageWithNumber:phoneNumber.number did:localDID];
                                      blockedContact.pendingUpload = !success;
                                      if (completion) {
                                          completion((error == nil), error);
                                      }
                                  }];
                              }];
}

+(void)unblockPendingBlockedContacts
{
    //TODO: do this.
}

+(void)unblockNumber:(BlockedContact *)blockedContact completion:(CompletionHandler)completion;
{
    [JCV5ApiClient unblockSMSMessageForDID:blockedContact.did
                                    number:blockedContact
                                completion:^(BOOL success, id response, NSError *error) {
                                    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
                                        BlockedContact *localBlockedContact = (BlockedContact *)[localContext objectWithID:blockedContact.objectID];
                                        if (success) {
                                            [localContext deleteObject:blockedContact];
                                        } else {
                                            localBlockedContact.markForDeletion = TRUE;
                                        }
                                        
                                        if (completion) {
                                            completion((error == nil), error);
                                        }
                                    }];
                                }];
}

+ (void)processBlockedResponseObject:(id)responseObject did:(DID *)did completion:(CompletionHandler)completion
{
    @try {
        // Is Array? We should have an array of blocked numbers.
        if (![responseObject isKindOfClass:[NSArray class]]) {
            [NSException raise:NSInvalidArgumentException format:@"Array is null"];
        }
        
        NSArray *blockedNumbers = (NSArray *)responseObject;
        [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
            
            // Get list of existing contacts. As we add contacts, if we come across a contact we
            // already know, we remove it from the list of contacts to be removed.
            DID *localDID = (DID *)[localContext objectWithID:did.objectID];
            NSMutableSet *blockedContactsToRemove = localDID.blockedContacts.mutableCopy;
            
            // Iterate over list of blocked numbers from the result. If we do not have a blocked
            // Contact, create one, otherwise just return existing one.
            for (id object in blockedNumbers) {
                if ([object isKindOfClass:[NSString class]]) {
                    BlockedContact *blockedContact = [self createBlockedMessageWithNumber:(NSString *)object did:localDID];
                    if ([blockedContactsToRemove containsObject:blockedContact]) {
                        [blockedContactsToRemove removeObject:blockedContact];
                    }
                }
            }
            
            // Any remaining blocked numbers that were not removed from our blockedContactsToRemove
            // array are now invalid, and are deleted from the local store.
            if (blockedContactsToRemove.count > 0) {
                for (BlockedContact *blockedContact in blockedContactsToRemove) {
                    [localDID.managedObjectContext deleteObject:blockedContact];
                }
            }
        } completion:^(BOOL success, NSError *error) {
            if (completion) {
                completion(success, error);
            }
        }];
    }
    @catch (NSException *exception) {
        NSInteger code;
        if (completion) {
            if ([exception.name isEqualToString:NSInvalidArgumentException]) {
                code = API_CLIENT_SMS_RESPONSE_INVALID;
            }
            completion(NO, [JCApiClientError errorWithCode:code]);
        }
    }
}

+ (BlockedContact *)createBlockedMessageWithNumber:(NSString *)number did:(DID *)did
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"did = %@ AND number = %@", did, number];
    BlockedContact *blockedContact = [BlockedContact MR_findFirstWithPredicate:predicate inContext:did.managedObjectContext];
    if (!blockedContact) {
        blockedContact = [BlockedContact MR_createInContext:did.managedObjectContext];
        blockedContact.number = number;
        blockedContact.did = did;
    }
    return blockedContact;
}

@end
