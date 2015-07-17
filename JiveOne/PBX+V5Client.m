//
//  PBX+V5Client.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 6/24/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "PBX+V5Client.h"

// V5 Client
#import "JCV5ApiClient+Jif.h"

// Managed Objects
#import "Line.h"
#import "User.h"
#import "DID.h"

NSString *const kPBXInfoResponseDataKey             = @"data";
NSString *const kPBXInfoResponseUserKey                 = @"user";
NSString *const kPBXInfoResponseUserJiveIdKey               = @"externalId";
NSString *const kPBXInfoResponseTenantsKey              = @"tenants";
NSString *const kPBXInfoResponseKey                         = @"pbxes";
NSString *const kPBXInfoResponseDomainKey                       = @"domain";
NSString *const kPBXInfoResponseIdentifierKey                   = @"id";
NSString *const kPBXInfoResponseNameKey                         = @"name";
NSString *const kPBXInfoResponseV5Key                           = @"v5";
NSString *const kPBXInfoResponseExtensionsKey                   = @"extensions";
NSString *const kPBXInfoResponseExtensionIdentifierKey              = @"id";
NSString *const kPBXInfoResponseExtensionNameKey                    = @"name";
NSString *const kPBXInfoResponseExtensionNumberKey                  = @"number";
NSString *const kPBXInfoResponseExtensionMailboxKey                 = @"mailbox";
NSString *const kPBXInfoResponseExtensionMailboxIdentiferKey            = @"id";
NSString *const kPBXInfoResponseExtensionMailboxUrlKey                  = @"self";
NSString *const kPBXInfoResponseUserInfoKey                     = @"userInfo";
NSString *const kPBXInfoResponseUserFirstNameKey                    = @"first";
NSString *const kPBXInfoResponseUserLastNameKey                     = @"last";
NSString *const kPBXInfoResponseUserNameKey                         = @"fullName";
NSString *const kPBXInfoResponseNumbersKey                      = @"phoneNumbers";
NSString *const kPBXInfoResponseNumberIdentifierKey                 = @"id";
NSString *const kPBXInfoResponseNumberDialStringKey                 = @"dialstring";
NSString *const kPBXInfoResponseNumberMakeCallsKey                  = @"makeCalls";
NSString *const kPBXInfoResponseNumberReceiveCallsKey               = @"receiveCalls";
NSString *const kPBXInfoResponseNumberSendSMSKey                    = @"sendSMS";
NSString *const kPBXInfoResponseNumberReceiveSMSKey                 = @"receiveSMS";

@implementation PBX (V5Client)

+ (void)downloadPbxInfoForUser:(User *)user completed:(CompletionHandler)completion
{
    [JCV5ApiClient requestPBXInforForUser:user competion:^(BOOL success, id responseObject, NSError *error) {
        if (success) {
            [self processRequestResponse:responseObject user:user competion:completion];
        }
        else
        {
            if (completion) {
                completion(NO, error);
            }
        }
    }];
}

+(void)processRequestResponse:(id)responseObject user:(User *)user competion:(CompletionHandler)completion
{
    @try {
        if (![responseObject isKindOfClass:[NSDictionary class]]) {
            [NSException raise:NSInvalidArgumentException format:@"Invalid pbxs response object."];
        }
        
        NSDictionary *data = [(NSDictionary *)responseObject dictionaryForKey:kPBXInfoResponseDataKey];
        if (!data) {
            [NSException raise:NSInvalidArgumentException format:@"Invalid pbx response data object."];
        }
        
        NSDictionary *userData = [data dictionaryForKey:kPBXInfoResponseUserKey];
        if (!userData) {
            [NSException raise:NSInvalidArgumentException format:@"Invalid pbx response user data object."];
        }
        
        NSString *jiveId = [userData stringValueForKey:kPBXInfoResponseUserJiveIdKey];
        if (![user.jiveUserId isEqualToString:jiveId]) {
            [NSException raise:NSInvalidArgumentException format:@"Pbx user does not match requested user id."];
        }
        
        NSDictionary *tenantsData = [data dictionaryForKey:kPBXInfoResponseTenantsKey];
        if (!tenantsData) {
            [NSException raise:NSInvalidArgumentException format:@"Invalid pbx response tenants object."];
        }
        
        NSArray *pbxesData = [tenantsData arrayForKey:kPBXInfoResponseKey];
        if (!pbxesData) {
            [NSException raise:NSInvalidArgumentException format:@"Invalid pbx response pbx array."];
        }
        
        [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
            [self processPbxArrayData:pbxesData user:(User *)[localContext objectWithID:user.objectID]];
        } completion:^(BOOL success, NSError *error) {
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

/**
 * Recieves an array of PBXs and iterates over them, saving them to core data. Exiting pbx that are 
 * not in the update array, are removed.
 */
+ (void)processPbxArrayData:(NSArray *)pbxsData user:(User *)user
{
    // Grab the Users pbxs before we start adding new ones or updating exiting ones.
    NSMutableSet *pbxs = user.pbxs.mutableCopy;
    
    for (NSDictionary *pbxData in pbxsData) {
        if ([pbxData isKindOfClass:[NSDictionary class]]) {
            PBX *pbx = [self processPbxData:pbxData forUser:user];
            if ([pbxs containsObject:pbx]) {
                [pbxs removeObject:pbx];
            }
        }
    }
    
    // If there are any pbxs left in the array, it means we have more pbxs than the server response,
    // and we need to delete the extra pbxs.
    if (pbxs.count > 0) {
        for (PBX *pbx in pbxs) {
            [user.managedObjectContext deleteObject:pbx];
        }
    }
}

+ (PBX *)processPbxData:(NSDictionary *)data forUser:(User *)user
{
    NSString *jrn = [data stringValueForKey:kPBXInfoResponseIdentifierKey];
    if (!jrn) {
        return nil;
    }
    
    // Fetch/update PBX. If does not exit it is created.
    PBX *pbx = [PBX pbxForJrn:jrn user:user];
    pbx.name   = [data stringValueForKey:kPBXInfoResponseNameKey];
    pbx.v5     = [data boolValueForKey:kPBXInfoResponseV5Key];
    pbx.domain = [data stringValueForKey:kPBXInfoResponseDomainKey];
    
    // Process Line Extensions
    NSArray *lines = [data arrayForKey:kPBXInfoResponseExtensionsKey];
    if (lines.count > 0) {
        [self processLines:lines pbx:pbx];
    }
    
    // Process Did Numbers;
    NSArray *numbers = [data arrayForKey:kPBXInfoResponseNumbersKey];
    if (numbers.count > 0) {
        [self processNumbers:numbers pbx:pbx];
    }
    return pbx;
}

+ (PBX *)pbxForJrn:(NSString *)jrn user:(User *)user
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"user = %@ and jrn = %@", user, jrn];
    PBX *pbx = [PBX MR_findFirstWithPredicate:predicate inContext:user.managedObjectContext];
    if (!pbx) {
        pbx = [PBX MR_createEntityInContext:user.managedObjectContext];
        pbx.jrn = jrn;
        pbx.user = user;
    }
    return pbx;
}

#pragma mark - Lines Info -

+ (void)processLines:(NSArray *)linesData pbx:(PBX *)pbx
{
    NSMutableArray *lines = [Line MR_findByAttribute:NSStringFromSelector(@selector(pbx)) withValue:pbx inContext:pbx.managedObjectContext].mutableCopy;
    for (id object in linesData){
        if ([object isKindOfClass:[NSDictionary class]]) {
            Line *line = [self processLine:(NSDictionary *)object pbx:pbx];
            if ([lines containsObject:line]) {
                [lines removeObject:line];
            }
        }
    }
    
    // If there are any pbxs left in the array, it means we have more pbxs than the server response,
    // and we need to delete the extra pbxs.
    if (lines.count > 0) {
        for (Line *line in lines) {
            [pbx.managedObjectContext deleteObject:line];
        }
    }
}

+ (Line *)processLine:(NSDictionary *)data pbx:(PBX *)pbx
{
    NSString *jrn = [data stringValueForKey:kPBXInfoResponseExtensionIdentifierKey];
    if (!jrn) {
        return nil;
    }
    
    Line *line = [self lineForJrn:jrn pbx:pbx];
    line.name     = [data stringValueForKey:kPBXInfoResponseExtensionNameKey];
    line.number   = [data stringValueForKey:kPBXInfoResponseExtensionNumberKey];
    
    NSDictionary *mailbox = [data dictionaryForKey:kPBXInfoResponseExtensionMailboxKey];
    if (mailbox) {
        line.mailboxJrn = [mailbox stringValueForKey:kPBXInfoResponseExtensionMailboxIdentiferKey];
        line.mailboxUrl = [mailbox stringValueForKey:kPBXInfoResponseExtensionMailboxUrlKey];
    }
    return line;
}

+ (Line *)lineForJrn:(NSString *)jrn pbx:(PBX *)pbx
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"pbx = %@ and jrn = %@", pbx, jrn];
    Line *line = [Line MR_findFirstWithPredicate:predicate inContext:pbx.managedObjectContext];
    if(!line) {
        line = [Line MR_createEntityInContext:pbx.managedObjectContext];
        line.jrn = jrn;
        line.pbx = pbx;
        line.pbxId = pbx.pbxId;
    }
    return line;
}

#pragma mark - Number Info -

+ (void)processNumbers:(NSArray *)numbersData pbx:(PBX *)pbx
{
    NSMutableSet *dids = pbx.dids.mutableCopy;
    
    for (id object in numbersData) {
        if ([object isKindOfClass:[NSDictionary class]]) {
            DID *did = [self processNumber:(NSDictionary *)object pbx:pbx];
            if ([dids containsObject:did]) {
                [dids removeObject:did];
            }
        }
    }
    
    if (dids.count > 0) {
        for (DID *did in dids) {
            [pbx.managedObjectContext deleteObject:did];
        }
    }
}

+(DID *)processNumber:(NSDictionary *)data pbx:(PBX *)pbx
{
    NSString *jrn = [data stringValueForKey:kPBXInfoResponseNumberIdentifierKey];
    if (!jrn) {
        return nil;
    }
    
    DID *did = [self didForJrn:jrn pbx:pbx];
    did.number      = [data stringValueForKey:kPBXInfoResponseNumberDialStringKey];
    did.makeCall    = [data boolValueForKey:kPBXInfoResponseNumberMakeCallsKey];
    did.receiveCall = [data boolValueForKey:kPBXInfoResponseNumberReceiveCallsKey];
    did.sendSMS     = [data boolValueForKey:kPBXInfoResponseNumberSendSMSKey];
    did.receiveSMS  = [data boolValueForKey:kPBXInfoResponseNumberReceiveSMSKey];
    return did;
}

+ (DID *)didForJrn:(NSString *)jrn pbx:(PBX *)pbx
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"pbx = %@ and jrn = %@", pbx, jrn];
    DID *did = [DID MR_findFirstWithPredicate:predicate inContext:pbx.managedObjectContext];
    if (!did) {
        did = [DID MR_createEntityInContext:pbx.managedObjectContext];
        did.jrn = jrn;
        did.pbx = pbx;
    }
    return did;
}

@end
