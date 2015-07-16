//
//  JCV5ApiClient.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 10/2/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCApiClient.h"
#import "JCConversationGroupObject.h"

@class User, Line, DID, Contact, ContactGroup;

@interface JCV5ApiClient : JCApiClient

+ (instancetype)sharedClient;

- (BOOL)isOperationRunning:(NSString *)operationName;

#pragma mark - PBX INFO (JIF) -

+ (void)requestPBXInforForUser:(User *)user
                     competion:(JCApiClientCompletionHandler)completion;

#pragma mark - Jedi -

+ (void)requestJediIdForDeviceToken:(NSString *)deviceToken
                         completion:(JCApiClientCompletionHandler)completion;

+ (void)updateJediFromOldDeviceToken:(NSString *)oldDeviceToken
                    toNewDeviceToken:(NSString *)newDeviceToken
                          completion:(JCApiClientCompletionHandler)completion;

#pragma mark - Jasmine -

+ (void)requestPrioritySessionForJediId:(NSString *)deviceToken
                             completion:(JCApiClientCompletionHandler)completion;

#pragma mark - Voicemail -

+ (void)downloadVoicemailsForLine:(Line *)line
                       completion:(JCApiClientCompletionHandler)completion;

#pragma mark - Internal Extensions -

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


#pragma mark - SMS Messaging -

+ (void)sendSMSMessageWithParameters:(NSDictionary *)parameters
                          completion:(JCApiClientCompletionHandler)completion;

+ (void)downloadMessagesDigestForDID:(DID *)did
                         completion:(JCApiClientCompletionHandler)completion;

+ (void)downloadMessagesForDID:(DID *)did
                    completion:(JCApiClientCompletionHandler)completion;

+ (void)downloadMessagesForDID:(DID *)did
           toConversationGroup:(id<JCConversationGroupObject>)conversationGroup
                    completion:(JCApiClientCompletionHandler)completion;

#pragma mark - SMS Message Blocking -

+ (void)blockSMSMessageForDID:(DID *)did
                       number:(id<JCPhoneNumberDataSource>)phoneNumber
                   completion:(JCApiClientCompletionHandler)completion;

+ (void)unblockSMSMessageForDID:(DID *)did
                         number:(id<JCPhoneNumberDataSource>)phoneNumber
                     completion:(JCApiClientCompletionHandler)completion;

+ (void)downloadMessagesBlockedForDID:(DID *)did
                           completion:(JCApiClientCompletionHandler)completion;
@end
