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
NSString *const kContactAddressesKey            = @"address";
NSString *const kContactAddressesCityKey        = @"city";
NSString *const kContactAddressesRegionKey      = @"region";
NSString *const kContactAddressesPostalCodeKey  = @"postalCode";
NSString *const kContactAddressTypeKey          = @"type";

NSString *const kContactOtherNodeKey        = @"other";
NSString *const kContactOtherKey                = @"key";
NSString *const kContactOtherValueKey           = @"value";

@implementation Contact (V5Client)

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
    contact.firstName   = [data stringValueForKey:kContactFirstNameKey];
    contact.lastName    = [data stringValueForKey:kContactLastNameKey];
    contact.etag        = [data stringValueForKey:kContactETagKey];
    
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
    
    return contact;
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
    for (NSDictionary *phoneNumberData in phoneNumbersData) {
        if ([phoneNumberData isKindOfClass:[NSDictionary class]]) {
            PhoneNumber *phoneNumber = [self processPhoneNumberData:phoneNumberData contact:contact];
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
    // TODO: Finish
    
    return nil;
}

#pragma mark Address

+(void)processAddressArrayData:(NSArray *)addressArrayData contact:(Contact *)contact
{
    NSMutableSet *addresses = contact.addresses.mutableCopy;
    for (NSDictionary *addressData in addressArrayData) {
        if ([addressData isKindOfClass:[NSDictionary class]]) {
            Address *address = [self processAddressData:addressData contact:contact];
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
    // TODO: Finish
    
    return nil;
}

#pragma mark Other

+(void)processOtherArrayData:(NSArray *)othersArrayData contact:(Contact *)contact
{
    NSMutableSet *info = contact.info.mutableCopy;
    for (NSDictionary *otherData in othersArrayData) {
        if ([otherData isKindOfClass:[NSDictionary class]]) {
            ContactInfo *contactInfo = [self processOtherData:otherData contact:contact];
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
    // TODO: Finish
    
    return nil;
}

#pragma mark - Upload -

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
        if (success) {
            [self processContactUploadResponse:response contact:contact completion:completion];
        } else {
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
    
}

-(NSDictionary *)serializedData
{
    NSMutableDictionary *data = [NSMutableDictionary new];
    [data setValue:self.contactId forKey:kContactContactIdKey];
    [data setValue:self.firstName forKey:kContactFirstNameKey];
    [data setValue:self.lastName forKey:kContactLastNameKey];
    
    // Phone numbers
    NSSet *phoneNumbers = self.phoneNumbers;
    NSMutableArray *phoneNumberData = [NSMutableArray arrayWithCapacity:phoneNumbers.count];
    for (PhoneNumber *phoneNumber in phoneNumbers) {
        [phoneNumberData addObject:[self phoneNumberDataForPhoneNumber:phoneNumber]];
    }
    [data setObject:phoneNumberData forKey:kContactPhoneNumbersNodeKey];
    
    // Address numbers.
    NSSet *addresses = self.addresses;
    NSMutableArray *addressesData = [NSMutableArray arrayWithCapacity:addresses.count];
    for (Address *address in addresses) {
        [addressesData addObject:[self addressBookDataForAddress:address]];
    }
    [data setObject:addressesData forKey:kContactAddressesNodeKey];
    
    // Info Data
    NSSet *info = self.info;
    NSMutableArray *infoData = [NSMutableArray arrayWithCapacity:info.count];
    for (ContactInfo *contactInfo in info) {
        [infoData addObject:@{ kContactOtherKey : contactInfo.key,
                               kContactOtherValueKey : contactInfo.value}];
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
    [data setValue:contactInfo.key forKey:kContactOtherKey];
    [data setValue:contactInfo.value forKey:kContactOtherValueKey];
    return data;
}

#pragma mark - Deletion -

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
