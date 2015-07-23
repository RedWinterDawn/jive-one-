//
//  JCV5ApiClient+Contacts.m
//  JiveOne
//
//  Created by Robert Barclay on 7/16/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCV5ApiClient+Contacts.h"

#import "Line.h"
#import "PBX.h"
#import "Contact+V5Client.h"
#import "ContactGroup+V5Client.h"

#ifndef GET_EXTENSIONS_NUMBER_OF_TRIES
#define GET_EXTENSIONS_NUMBER_OF_TRIES 1
#endif

#ifndef GET_CONTACTS_NUMBER_OF_TRIES
#define GET_CONTACTS_NUMBER_OF_TRIES 1
#endif

#ifndef UPLOAD_CONTACT_NUMBER_OF_TRIES
#define UPLOAD_CONTACT_NUMBER_OF_TRIES 1
#endif

#ifndef DELETE_CONTACT_NUMBER_OF_TRIES
#define DELETE_CONTACT_NUMBER_OF_TRIES 1
#endif

// Extensions
NSString *const kJCV5ApiExtensionsRequestPath       = @"/contacts/2014-07/%@/line/id/%@";

// Contacts
NSString *const kJCV5ApiContactsDownloadRequestPath = @"/contacts/v3/user/contacts";
NSString *const kJCV5ApiContactDownloadRequestPath  = @"/contacts/v3/user/contact/%@";
NSString *const kJCV5ApiContactUploadRequestPath    = @"/contacts/v3/user/contact";

// Groups
NSString *const kJCV5ApiContactGroupUploadRequestPath   = @"/contacts/v3/user/group/";
NSString *const kJCV5ApiContactGroupDeleteRequestPath   = @"/contacts/v3/user/group/%@";

// Contact Group Associations
NSString *const kJCV5ApiContactGroupAddAssociationRequestPath      = @"/contacts/v3/user/group/add/%@";
NSString *const kJCV5ApiContactGroupRemoveAssociationRequestPath   = @"/contacts/v3/user/group/remove/%@";

@implementation JCV5ApiClient (Contacts)

+ (void)downloadInternalExtensionsForLine:(Line *)line completion:(JCApiClientCompletionHandler)completion
{
    if (!line) {
        if (completion) {
            completion(NO, nil, [JCApiClientError errorWithCode:API_CLIENT_INVALID_ARGUMENTS reason:@"Line Is Null"]);
        }
        return;
    }
    
    NSString *path = [NSString stringWithFormat:kJCV5ApiExtensionsRequestPath, line.pbx.pbxId, line.lineId];
    [self getWithPath:path
           parameters:nil
    requestSerializer:nil
              retries:GET_EXTENSIONS_NUMBER_OF_TRIES
           completion:completion];
}

+ (void)downloadContactsWithCompletion:(JCApiClientCompletionHandler)completion
{
    [self getWithPath:kJCV5ApiContactsDownloadRequestPath
           parameters:nil
    requestSerializer:nil
              retries:GET_CONTACTS_NUMBER_OF_TRIES
           completion:completion];
}

+ (void)downloadContact:(Contact *)contact completion:(JCApiClientCompletionHandler)completion
{
    if (!contact) {
        if (completion) {
            completion(NO, nil, [JCApiClientError errorWithCode:API_CLIENT_INVALID_ARGUMENTS reason:@"Contact Is Null"]);
        }
        return;
    }
    
    NSString *path = [NSString stringWithFormat:kJCV5ApiContactDownloadRequestPath, contact.contactId];
    [self getWithPath:path
           parameters:nil
    requestSerializer:nil
              retries:GET_CONTACTS_NUMBER_OF_TRIES
           completion:completion];
}

+ (void)uploadContact:(Contact *)contact completion:(JCApiClientCompletionHandler)completion
{
    if (!contact) {
        if (completion) {
            completion(NO, nil, [JCApiClientError errorWithCode:API_CLIENT_INVALID_ARGUMENTS reason:@"Contact Is Null"]);
        }
        return;
    }
    
    
    NSDictionary *serializedData = contact.serializedData;
    if (!contact.contactId) {
        [self postWithPath:kJCV5ApiContactUploadRequestPath
                parameters:serializedData
         requestSerializer:[JCBearerAuthenticationJSONRequestSerializer new]
                   retries:UPLOAD_CONTACT_NUMBER_OF_TRIES
                completion:completion];
    }
    else {
        [self putWithPath:kJCV5ApiContactUploadRequestPath
               parameters:serializedData
        requestSerializer:[JCBearerAuthenticationJSONRequestSerializer new]
                  retries:UPLOAD_CONTACT_NUMBER_OF_TRIES
               completion:completion];
    }
}

+ (void)deleteContact:(Contact *)contact conpletion:(JCApiClientCompletionHandler)completion
{
    if (!contact) {
        if (completion) {
            completion(NO, nil, [JCApiClientError errorWithCode:API_CLIENT_INVALID_ARGUMENTS reason:@"Contact Is Null"]);
        }
        return;
    }
    
    NSString *path = [NSString stringWithFormat:kJCV5ApiContactDownloadRequestPath, contact.contactId];
    [self deleteWithPath:path
              parameters:nil
       requestSerializer:nil
                 retries:DELETE_CONTACT_NUMBER_OF_TRIES
              completion:completion];
}

+ (void)downloadContactGroupsWithCompletion:(JCApiClientCompletionHandler)completion
{
    //  TODO: not yet implemented server side.
    if (completion) {
        completion(YES, nil, nil);
    }
}

+ (void)uploadContactGroup:(ContactGroup *)contactGroup completion:(JCApiClientCompletionHandler)completion
{
    if (!contactGroup) {
        if (completion) {
            completion(NO, nil, [JCApiClientError errorWithCode:API_CLIENT_INVALID_ARGUMENTS reason:@"Contact Group Is Null"]);
        }
        return;
    }
    
    NSString *path = kJCV5ApiContactGroupUploadRequestPath;
    AFHTTPRequestSerializer *serializer = [JCBearerAuthenticationJSONRequestSerializer new];
    NSDictionary *serializedData = contactGroup.serializedData;
    if (!contactGroup.groupId) {
        [self postWithPath:path
                parameters:serializedData
         requestSerializer:serializer
                   retries:UPLOAD_CONTACT_NUMBER_OF_TRIES
                completion:completion];
    }
    else {
        [self putWithPath:path
               parameters:serializedData
        requestSerializer:serializer
                  retries:UPLOAD_CONTACT_NUMBER_OF_TRIES
               completion:completion];
    }
}

+ (void)deleteContactGroup:(ContactGroup *)contactGroup completion:(JCApiClientCompletionHandler)completion
{
    if (!contactGroup) {
        if (completion) {
            completion(NO, nil, [JCApiClientError errorWithCode:API_CLIENT_INVALID_ARGUMENTS reason:@"Contact Group Is Null"]);
        }
        return;
    }
    
    
    if (!contactGroup.groupId) {
        if (completion) {
            completion(YES, nil, nil);
        }
        return;
    }
    
    
    NSString *path = [NSString stringWithFormat:kJCV5ApiContactGroupDeleteRequestPath, contactGroup.groupId];
    [self deleteWithPath:path
              parameters:nil
       requestSerializer:[JCBearerAuthenticationJSONRequestSerializer new]
                 retries:DELETE_CONTACT_NUMBER_OF_TRIES
              completion:completion];
}

+ (void)associatedContactGroupAssociations:(NSDictionary *)contactGroupAssociations completion:(JCApiClientCompletionHandler)handler
{
    NSArray *groups = contactGroupAssociations.allKeys;
    NSMutableArray *remaining = groups.mutableCopy;
    for (NSString *group in groups) {
        
        NSString *path = [NSString stringWithFormat:kJCV5ApiContactGroupAddAssociationRequestPath, group];
        NSArray *contactIds = [contactGroupAssociations objectForKey:group];
        
        NSLog(@"%@ -> %@", path, contactIds);
    }
}

+ (void)disassociatedContactGroupAssociations:(NSDictionary *)contactGroupAssociations completion:(JCApiClientCompletionHandler)handler
{
    NSArray *groups = contactGroupAssociations.allKeys;
    NSMutableArray *remaining = groups.mutableCopy;
    for (NSString *group in groups) {
        
        NSString *path = [NSString stringWithFormat:kJCV5ApiContactGroupRemoveAssociationRequestPath, group];
        NSArray *contactIds = [contactGroupAssociations objectForKey:group];
        
        NSLog(@"%@ -> %@", path, contactIds);
    }
}

@end
