//
//  Contact+V5Client.m
//  JiveOne
//
//  Created by Robert Barclay on 6/15/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "Contact+V5Client.h"

// Client
#import "JCV5ApiClient.h"

// Models
#import "User.h"
#import "Contact.h"
#import "PhoneNumber.h"
#import "Address.h"
#import "ContactInfo.h"

#import "NSDictionary+Validations.h"

NSString *const kContactContactIdKey        = @"id";
NSString *const kContactFirstNameKey        = @"firstName";
NSString *const kContactLastNameKey         = @"lastName";


NSString *const kContactETagKey             = @"etag";
NSString *const kContactCreated             = @"created";

NSString *const kContactPhoneNumbersNodeKey = @"phoneNumber";
NSString *const kContactPhoneNumberTypeKey      = @"type";
NSString *const kContactPhoneNumberNumberKey    = @"number";

NSString *const kContactAddressesNodeKey    = @"address";
NSString *const kContactAddressesHashKey        = @"hash";
NSString *const kContactAddressesKey            = @"address";
NSString *const kContactAddressesCityKey        = @"city";
NSString *const kContactAddressesRegionKey      = @"region";
NSString *const kContactAddressesPostalCodeKey  = @"postalCode";
NSString *const kContactAddressTypeKey          = @"type";

NSString *const kContactOtherNodeKey        = @"other";
NSString *const kContactOtherHashKey            = @"hash";
NSString *const kContactOtherTypeKey            = @"type";
NSString *const kContactOtherKey                = @"key";
NSString *const kContactOtherValueKey           = @"value";

@implementation Contact (V5Client)

+ (void)syncContactsForUser:(User *)user completion:(CompletionHandler)completion
{
    [self deleteMarkedContactsForUser:user completion:^(BOOL success, NSError *error) {
        if (success) {
            [self uploadMarkedContactsForUser:user completion:^(BOOL success, NSError *error) {
                if (success) {
                    [self downloadContactsForUser:user completion:completion];
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

+ (void)syncContact:(Contact *)contact completion:(CompletionHandler)completion
{
    // if we have a pending upload, do the update rather than a download. We will be updated to be
    // the latest version.
    if (contact.isMarkedForUpdate) {
        [self uploadContact:contact completion:completion];
        return;
    }
    
    [self downloadContact:contact completion:completion];
}

#pragma mark - Download -

+ (void)downloadContactsForUser:(User *)user completion:(CompletionHandler)completion
{
    [JCV5ApiClient downloadContactsWithCompletion:^(BOOL success, id response, NSError *error) {
        if (success) {
            [self processContactsDownloadResponse:response user:user completion:completion];
        } else {
            if (completion) {
                completion(NO, error);
            }
        }
    }];
}

+ (void)downloadContact:(Contact *)contact completion:(CompletionHandler)completion
{
    [JCV5ApiClient downloadContact:contact completion:^(BOOL success, id response, NSError *error) {
        if (success) {
            if (![response isKindOfClass:[NSDictionary class]]) {
                if (completion) {
                    completion(NO, [JCApiClientError errorWithCode:API_CLIENT_RESPONSE_ERROR reason:NSLocalizedString(@"Invalid contacts response. Expecting an object", @"Download Contact")]);
                }
            } else {
                NSDictionary *contactData = (NSDictionary *)response;
                [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
                    [self processContactData:contactData user:(User *)[localContext objectWithID:contact.user.objectID]];
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
        } else {
            if (completion) {
                completion(NO, error);
            }
        }
    }];
}

#pragma mark Private

+ (void)processContactsDownloadResponse:(id)responseObject user:(User *)user completion:(CompletionHandler)completion
{
    @try {
        if (![responseObject isKindOfClass:[NSArray class]]) {
            [NSException raise:NSInvalidArgumentException format:@"Invalid contacts response. Expecting an Array"];
        }
        
        NSArray *contactsData = (NSArray *)responseObject;
        [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
            [self processContactsArrayData:contactsData user:(User *)[localContext objectWithID:user.objectID]];
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
    @catch (NSException *exception) {
        if (completion) {
            completion(NO, [JCApiClientError errorWithCode:API_CLIENT_RESPONSE_ERROR reason:exception.reason]);
        }
    }
}

+ (void)processContactsArrayData:(NSArray *)contactsData user:(User *)user
{
    NSMutableSet *contacts = user.contacts.mutableCopy;
    for (NSDictionary *contactData in contactsData) {
        if ([contactData isKindOfClass:[NSDictionary class]]) {
            Contact *contact = [self processContactData:contactData user:user];
            if ([contacts containsObject:contact]) {
                [contacts removeObject:contact];
            }
        }
    }
    
    // If there are any contacts left in the array, it means we have more contacts than the server
    // response, and we need to delete the extra contacts from our device.
    if (contacts.count > 0) {
        for (Contact *contact in contacts) {
            [user.managedObjectContext deleteObject:contact];
        }
    }
}

+ (Contact *)processContactData:(NSDictionary *)data user:(User *)user
{
    NSString *contactId = [data stringValueForKey:kContactContactIdKey];
    if (!contactId) {
        return nil;
    }
    
    Contact *contact = [self contactForContactId:contactId user:user];
    
    [self updateContact:contact data:data];
    
    return contact;
}

+ (void)updateContact:(Contact *)contact data:(NSDictionary *)data
{
    contact.firstName   = [data stringValueForKey:kContactFirstNameKey];
    contact.lastName    = [data stringValueForKey:kContactLastNameKey];
    contact.etag        = [data integerValueForKey:kContactETagKey];
    
    // Phone numbers
    NSArray *phoneNumbers = [data arrayForKey:kContactPhoneNumbersNodeKey];
    if (phoneNumbers) {
        [self processPhoneNumberArrayData:phoneNumbers contact:contact];
    }
    
    // Addresses
    NSArray *addresses = [data arrayForKey:kContactAddressesNodeKey];
    if (addresses) {
        [self processAddressArrayData:addresses contact:contact];
    }
    
    // Other
    NSArray *other = [data arrayForKey:kContactOtherNodeKey];
    if (other) {
        [self processAddressArrayData:other contact:contact];
    }
}

+ (Contact *)contactForContactId:(NSString *)contactId user:(User *)user
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"user = %@ AND contactId = %@", user, contactId];
    Contact *contact = [Contact MR_findFirstWithPredicate:predicate inContext:user.managedObjectContext];
    if (!contact) {
        contact = [Contact MR_createEntityInContext:user.managedObjectContext];
        contact.contactId = contactId;
        contact.user = user;
    }
    return contact;
}

#pragma mark PhoneNumber

+(void)processPhoneNumberArrayData:(NSArray *)phoneNumbersData contact:(Contact *)contact
{
    NSMutableSet *phoneNumbers = contact.phoneNumbers.mutableCopy;
    for (int index = 0; index < phoneNumbersData.count; index++) {
        NSDictionary *phoneNumberData = [phoneNumbersData objectAtIndex:index];
        if ([phoneNumberData isKindOfClass:[NSDictionary class]]) {
            PhoneNumber *phoneNumber = [self processPhoneNumberData:phoneNumberData contact:contact];
            phoneNumber.order = index;
            if ([phoneNumbers containsObject:phoneNumber]) {
                [phoneNumbers removeObject:phoneNumber];
            }
        }
    }
    
    // If there are any contacts left in the array, it means we have more contacts than the server
    // response, and we need to delete the extra contacts from our device.
    if (phoneNumbers.count > 0) {
        for (PhoneNumber *phoneNumber in phoneNumbers) {
            [contact.managedObjectContext deleteObject:phoneNumber];
        }
    }
}

+(PhoneNumber *)processPhoneNumberData:(NSDictionary *)data contact:(Contact *)contact
{
    NSString *number = [data stringValueForKey:kContactPhoneNumberNumberKey];
    if (!number) {
        return nil;
    }
    
    // Get Phone number
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"number = %@ AND contact = %@", number, contact];
    PhoneNumber *phoneNumber = [PhoneNumber MR_findFirstWithPredicate:predicate inContext:contact.managedObjectContext];
    if (!phoneNumber) {
        phoneNumber = [PhoneNumber MR_createEntityInContext:contact.managedObjectContext];
        phoneNumber.number = number;
        phoneNumber.contact = contact;
    }
    
    // Update phone number
    phoneNumber.type = [data stringValueForKey:kContactPhoneNumberTypeKey];
    
    return phoneNumber;
}

#pragma mark Address

+(void)processAddressArrayData:(NSArray *)addressArrayData contact:(Contact *)contact
{
    NSMutableSet *addresses = contact.addresses.mutableCopy;
    for (int index = 0; index < addressArrayData.count; index++) {
        NSDictionary *addressData = [addressArrayData objectAtIndex:index];
        if ([addressData isKindOfClass:[NSDictionary class]]) {
            Address *address = [self processAddressData:addressData contact:contact];
            address.order = index;
            if ([addresses containsObject:address]) {
                [addresses removeObject:address];
            }
        }
    }
    
    // If there are any contacts left in the array, it means we have more contacts than the server
    // response, and we need to delete the extra contacts from our device.
    if (addresses.count > 0) {
        for (Address *address in addresses) {
            [contact.managedObjectContext deleteObject:address];
        }
    }
}

+(Address *)processAddressData:(NSDictionary *)data contact:(Contact *)contact
{
    NSString *hash = [data stringValueForKey:kContactAddressesHashKey];
    
    Address *address = [self addressForHash:hash contact:contact];
    address.thoroughfare = [data stringValueForKey:kContactAddressesKey];
    address.city         = [data stringValueForKey:kContactAddressesCityKey];
    address.region       = [data stringValueForKey:kContactAddressesRegionKey];
    address.postalCode   = [data stringValueForKey:kContactAddressesPostalCodeKey];
    address.type         = [data stringValueForKey:kContactAddressTypeKey];
    
    return address;
}

+ (Address *)addressForHash:(NSString *)hash contact:(Contact *)contact
{
    Address *address;
    if (!hash) {
        address = [Address MR_createEntityInContext:contact.managedObjectContext];
        address.contact = contact;
        return address;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"dataHash = %@ AND contact = @%", hash, contact];
    address = [Address MR_findFirstWithPredicate:predicate inContext:contact.managedObjectContext];
    if (!address) {
        address = [Address MR_createEntityInContext:contact.managedObjectContext];
        address.contact = contact;
    }
    return address;
}

#pragma mark Other

+(void)processOtherArrayData:(NSArray *)othersArrayData contact:(Contact *)contact
{
    NSMutableSet *info = contact.info.mutableCopy;
    for (int index = 0; index < othersArrayData.count; index++) {
        NSDictionary *otherData = [othersArrayData objectAtIndex:index];
        if ([otherData isKindOfClass:[NSDictionary class]]) {
            ContactInfo *contactInfo = [self processOtherData:otherData contact:contact];
            contactInfo.order = index;
            if ([info containsObject:contactInfo]) {
                [info removeObject:contactInfo];
            }
        }
    }
    
    // If there are any contacts left in the array, it means we have more contacts than the server
    // response, and we need to delete the extra contacts from our device.
    if (info.count > 0) {
        for (ContactInfo *contactInfo in info) {
            [contact.managedObjectContext deleteObject:contactInfo];
        }
    }
}

+(ContactInfo *)processOtherData:(NSDictionary *)data contact:(Contact *)contact
{
    NSString *hash = [data stringValueForKey:kContactAddressesHashKey];
    ContactInfo *contactInfo = [self contactInfoForHash:hash contact:contact];
    contactInfo.type  = [data stringValueForKey:kContactOtherTypeKey];
    contactInfo.key   = [data stringValueForKey:kContactOtherKey];
    contactInfo.value = [data stringValueForKey:kContactOtherValueKey];
    return contactInfo;
}

+(ContactInfo *)contactInfoForHash:(NSString *)hash contact:(Contact *)contact
{
    ContactInfo *contactInfo;
    if (!hash) {
        contactInfo = [ContactInfo MR_createEntityInContext:contact.managedObjectContext];
        contactInfo.contact = contact;
        return contactInfo;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"dataHash = %@ AND contact = @%", hash, contact];
    contactInfo = [ContactInfo MR_findFirstWithPredicate:predicate inContext:contact.managedObjectContext];
    if (!contactInfo) {
        contactInfo = [ContactInfo MR_createEntityInContext:contact.managedObjectContext];
        contactInfo.contact = contact;
    }
    return contactInfo;
}

#pragma mark - Upload -

+ (void)uploadMarkedContactsForUser:(User *)user completion:(CompletionHandler)completion
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"markForUpdate = %@ AND user = %@", @YES, user];
    __block NSMutableArray *pendingContactsToUpdate = [Contact MR_findAllWithPredicate:predicate inContext:user.managedObjectContext].mutableCopy;
    
    // If we do not have any to delete, call completion.
    if (pendingContactsToUpdate.count == 0) {
        if (completion) {
            completion(YES, nil);
        }
        return;
    }
    
    // Iterate through each contact to delete.
    __block NSError *batchError;
    for (Contact *contact in pendingContactsToUpdate) {
        [self uploadContact:contact completion:^(BOOL success, NSError *error) {
            if (error && !batchError) {
                batchError = error;
            }
            
            [pendingContactsToUpdate removeObject:contact];
            if (pendingContactsToUpdate.count == 0) {
                if (completion) {
                    completion((batchError == nil), batchError );
                }
            }
        }];
    }
}

/**
 * Mark the contact for upload. Save changes made before we upload, then try to upload it.
 */
- (void)markForUpdate:(CompletionHandler)completion
{
    self.markForUpdate = TRUE;
    [self.managedObjectContext MR_saveToPersistentStoreWithCompletion:^(BOOL contextDidSave, NSError *error) {
        if(!error) {
            [[self class] uploadContact:self completion:completion];
        } else {
            if (completion) {
                completion(contextDidSave, error);
            }
        }
    }];
}

+ (void)uploadContact:(Contact *)contact completion:(CompletionHandler)completion
{
    [JCV5ApiClient uploadContact:contact completion:^(BOOL success, id response, NSError *error) {
        
        // If we do not get a response, we had a fatal error, so we call completion with an error.
        if (!response) {
            if (completion) {
                completion(NO, [JCApiClientError errorWithCode:API_CLIENT_RESPONSE_ERROR underlyingError:error]);
            }
        }
        
        if (![response isKindOfClass:[NSDictionary class]]) {
            if (completion) {
                completion(NO, [JCApiClientError errorWithCode:API_CLIENT_RESPONSE_ERROR reason:@"Unexpected response object"]);
            }
        }
        
        NSDictionary *contactData = (NSDictionary *)response;
        
        // If we received success, it means we updated correctly, and were in sync with the etag
        // versioning of the contact.
        if (success) {
            [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
                Contact *localContact = (Contact *)[localContext objectWithID:contact.objectID];
                localContact.contactId       = [contactData stringValueForKey:kContactContactIdKey];
                localContact.etag            = [contactData integerValueForKey:kContactETagKey];
                localContact.markForUpdate   = FALSE;
            } completion:^(BOOL contextDidSave, NSError *error) {
                
            }];
        } else {
            //[self updateContact:contact data:contactData];
            
            
            
            
            
            
            if (completion) {
                completion(NO, error);
            }
        }
    }];
}

#pragma mark Private

+ (void)processContactUploadResponse:(id)responseObject contact:(Contact *)contact completion:(CompletionHandler)completion
{
    @try {
        
        NSDictionary *contactData = nil;
        [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
            [self processContactUpload:contactData contact:(Contact *)[localContext objectWithID:contact.objectID]];
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
    @catch (NSException *exception) {
        if (completion) {
            completion(NO, [JCApiClientError errorWithCode:API_CLIENT_RESPONSE_ERROR reason:exception.reason]);
        }
    }
}

+ (void)processContactUpload:(NSDictionary *)contactData contact:(Contact *)contact
{
    contact.contactId = [contactData stringValueForKey:kContactContactIdKey];
    
    [self updateContact:contact data:contactData];
    
    
    
    
    
    
    
}

-(NSDictionary *)serializedData
{
    NSMutableDictionary *data = [NSMutableDictionary new];
    [data setValue:self.contactId forKey:kContactContactIdKey];
    [data setValue:self.firstName forKey:kContactFirstNameKey];
    [data setValue:self.lastName forKey:kContactLastNameKey];
    [data setObject:[NSNumber numberWithInteger:self.etag] forKey:kContactETagKey];
    
    // Phone numbers
    NSArray *phoneNumbers = [self.phoneNumbers.allObjects sortedArrayUsingSelector:@selector(order)];
    NSMutableArray *phoneNumberData = [NSMutableArray arrayWithCapacity:phoneNumbers.count];
    for (PhoneNumber *phoneNumber in phoneNumbers) {
        [phoneNumberData addObject:[self phoneNumberDataForPhoneNumber:phoneNumber]];
    }
    [data setObject:phoneNumberData forKey:kContactPhoneNumbersNodeKey];
    
    // Address numbers.
    NSArray *addresses = [self.addresses.allObjects sortedArrayUsingSelector:@selector(order)];
    NSMutableArray *addressesData = [NSMutableArray arrayWithCapacity:addresses.count];
    for (Address *address in addresses) {
        [addressesData addObject:[self addressBookDataForAddress:address]];
    }
    [data setObject:addressesData forKey:kContactAddressesNodeKey];
    
    // Info Data
    NSArray *info = [self.info.allObjects sortedArrayUsingSelector:@selector(order)];
    NSMutableArray *infoData = [NSMutableArray arrayWithCapacity:info.count];
    for (ContactInfo *contactInfo in info) {
        [infoData addObject:[self otherDataForContactInfo:contactInfo]];
    }
    [data setObject:infoData forKey:kContactOtherNodeKey];
    
    return data;
}

-(NSDictionary *)phoneNumberDataForPhoneNumber:(PhoneNumber *)phoneNumber
{
    NSMutableDictionary *data = [NSMutableDictionary new];
    [data setValue:phoneNumber.type forKey:kContactPhoneNumberTypeKey];
    [data setValue:phoneNumber.number forKey:kContactPhoneNumberNumberKey];
    return data;
}

-(NSDictionary *)addressBookDataForAddress:(Address *)address
{
    NSMutableDictionary *data = [NSMutableDictionary new];
    [data setValue:address.dataHash forKey:kContactAddressesHashKey];
    [data setValue:address.type forKey:kContactAddressesPostalCodeKey];
    [data setValue:address.thoroughfare forKey:kContactAddressesPostalCodeKey];
    [data setValue:address.city forKey:kContactAddressesPostalCodeKey];
    [data setValue:address.region forKey:kContactAddressesPostalCodeKey];
    [data setValue:address.postalCode forKey:kContactAddressesPostalCodeKey];
    return data;
}

-(NSDictionary *)otherDataForContactInfo:(ContactInfo *)contactInfo
{
    NSMutableDictionary *data = [NSMutableDictionary new];
    [data setValue:contactInfo.dataHash forKey:kContactOtherHashKey];
    [data setValue:contactInfo.type forKey:kContactOtherTypeKey];
    [data setValue:contactInfo.key forKey:kContactOtherKey];
    [data setValue:contactInfo.value forKey:kContactOtherValueKey];
    return data;
}

#pragma mark - Deletion -

+ (void)deleteMarkedContactsForUser:(User *)user completion:(CompletionHandler)completion
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"markForDeletion = %@ AND user = %@", @YES, user];
    __block NSMutableArray *pendingContactsToDelete = [Contact MR_findAllWithPredicate:predicate inContext:user.managedObjectContext].mutableCopy;
    
    // If we do not have any to delete, call completion.
    if (pendingContactsToDelete.count == 0) {
        if (completion) {
            completion(YES, nil);
        }
        return;
    }
    
    // Iterate through each contact to delete.
    __block NSError *batchError;
    for (Contact *contact in pendingContactsToDelete) {
        [self deleteContact:contact completion:^(BOOL success, NSError *error) {
            if (error && !batchError) {
                batchError = error;
            }
            
            [pendingContactsToDelete removeObject:contact];
            if (pendingContactsToDelete.count == 0) {
                if (completion) {
                    completion((batchError == nil), batchError );
                }
            }
        }];
    }
}

/**
 * Mark the contact for deletion, save it, and then try to delete it server side. By saving before
 * we initiate the serve calls, we remove it from the UI, but it is still present in the database
 * until it gets officially removed by a succesfull server response.
 */
- (void)markForDeletion:(CompletionHandler)completion
{
    self.markForDeletion = TRUE;
    [self.managedObjectContext MR_saveToPersistentStoreWithCompletion:^(BOOL contextDidSave, NSError *error) {
        if (contextDidSave) {
            [[self class] deleteContact:self completion:completion];
        }
        else {
            if (completion) {
                completion(contextDidSave, error);
            }
        }
    }];
}

+ (void)deleteContact:(Contact *)contact completion:(CompletionHandler)completion
{
    [JCV5ApiClient deleteContact:contact conpletion:^(BOOL success, id response, NSError *error) {
        if (success)
        {
            [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
                [localContext deleteObject:[localContext objectWithID:contact.objectID]];
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
