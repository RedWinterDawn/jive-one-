//
//  JCV5ApiClient+Contacts.h
//  JiveOne
//
//  Created by Robert Barclay on 7/16/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCV5ApiClient.h"

@class Line, Contact, ContactGroup;

@interface JCV5ApiClient (Contacts)

+ (void)downloadInternalExtensionsForLine:(Line *)line
                               completion:(JCApiClientCompletionHandler)completion;

#pragma mark - Contacts -

+ (void)downloadContactsWithCompletion:(JCApiClientCompletionHandler)completion;

+ (void)downloadContact:(Contact *)contact
             completion:(JCApiClientCompletionHandler)completion;

+ (void)uploadContact:(Contact *)contact
           completion:(JCApiClientCompletionHandler)completion;

+ (void)deleteContact:(Contact *)contact
           conpletion:(JCApiClientCompletionHandler)completion;

#pragma mark Contact Groups

+ (void)downloadContactGroupsWithCompletion:(JCApiClientCompletionHandler)completion;

+ (void)uploadContactGroup:(ContactGroup *)contactGroup
                completion:(JCApiClientCompletionHandler)completion;

+ (void)deleteContactGroup:(ContactGroup *)contactGroup
                completion:(JCApiClientCompletionHandler)completion;

#pragma mark Contact Group Associataions

+ (void)associatedContactGroupAssociations:(NSDictionary *)contactGroupAssociations
                                completion:(JCApiClientCompletionHandler)handler;

+ (void)disassociatedContactGroupAssociations:(NSDictionary *)contactGroupAssociations
                                   completion:(JCApiClientCompletionHandler)handler;

@end
