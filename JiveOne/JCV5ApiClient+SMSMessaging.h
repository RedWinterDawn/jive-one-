//
//  JCV5ApiClient+SMSMessaging.h
//  JiveOne
//
//  Created by Robert Barclay on 7/16/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCV5ApiClient.h"

#import "JCPhoneNumberDataSource.h"
#import "JCConversationGroupObject.h"

@class DID;

@interface JCV5ApiClient (SMSMessaging)

#pragma mark - SMS Messages -

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
