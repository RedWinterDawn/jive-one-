//
//  JCV5ApiClient.h
//  JiveOne
//
//  Created by Eduardo Gueiros on 10/2/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCApiClient.h"
#import "JCConversationGroupObject.h"

typedef void(^JCV5ApiClientCompletionHandler)(BOOL success, id response, NSError *error);

@interface JCV5ApiClient : JCApiClient

+ (instancetype)sharedClient;

- (BOOL)isOperationRunning:(NSString *)operationName;

#pragma mark - PBX INFO -

+ (void)requestPBXInforForUser:(User *)user
                     competion:(JCV5ApiClientCompletionHandler)completion;


#pragma mark - SMS Messaging -

+ (void)sendSMSMessageWithParameters:(NSDictionary *)parameters
                          completion:(JCV5ApiClientCompletionHandler)completion;

+ (void)downloadMessagesDigestForDID:(DID *)did
                         completion:(JCV5ApiClientCompletionHandler)completion;

+ (void)downloadMessagesForDID:(DID *)did
                    completion:(JCV5ApiClientCompletionHandler)completion;

+ (void)downloadMessagesForDID:(DID *)did
           toConversationGroup:(id<JCConversationGroupObject>)conversationGroup
                    completion:(JCV5ApiClientCompletionHandler)completion;

#pragma mark - SMS Message Blocking -

+ (void)blockSMSMessageForDID:(DID *)did
                       number:(id<JCPhoneNumberDataSource>)phoneNumber
                   completion:(JCV5ApiClientCompletionHandler)completion;

+ (void)unblockSMSMessageForDID:(DID *)did
                         number:(id<JCPhoneNumberDataSource>)phoneNumber
                     completion:(JCV5ApiClientCompletionHandler)completion;

+ (void)downloadMessagesBlockedForDID:(DID *)did
                           completion:(JCV5ApiClientCompletionHandler)completion;
@end
