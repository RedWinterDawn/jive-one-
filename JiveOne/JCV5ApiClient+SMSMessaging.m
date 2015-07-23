//
//  JCV5ApiClient+SMSMessaging.m
//  JiveOne
//
//  Created by Robert Barclay on 7/16/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCV5ApiClient+SMSMessaging.h"

#import "DID.h"

#ifndef MESSAGES_SEND_NUMBER_OF_TRIES
#define MESSAGES_SEND_NUMBER_OF_TRIES 1
#endif

#ifndef CONVERSATIONS_DOWNLOAD_NUMBER_OF_TRIES
#define CONVERSATIONS_DOWNLOAD_NUMBER_OF_TRIES 1
#endif

#ifndef MESSAGES_DOWNLOAD_NUMBER_OF_TRIES
#define MESSAGES_DOWNLOAD_NUMBER_OF_TRIES 1
#endif

#ifndef MESSAGES_BLOCK_NUMBER_OF_TRIES
#define MESSAGES_BLOCK_NUMBER_OF_TRIES 1
#endif

#ifndef MESSAGES_UNBLOCK_NUMBER_OF_TRIES
#define MESSAGES_UNBLOCK_NUMBER_OF_TRIES 1
#endif

#ifndef MESSAGES_BLOCKED_NUMBER_DOWNLOAD_NUMBER_OF_TRIES
#define MESSAGES_BLOCKED_NUMBER_DOWNLOAD_NUMBER_OF_TRIES 1
#endif

// SMS Messaging
NSString *const kJCV5ApiSMSMessageSendRequestUrlPath                   = @"sms/send";
NSString *const kJCV5ApiSMSMessageRequestConversationsDigestURLPath    = @"sms/digest/did/%@/";
NSString *const kJCV5ApiSMSMessageRequestConversationsURLPath          = @"sms/messages/did/%@";
NSString *const kJCV5ApiSMSMessageRequestConversationURLPath           = @"sms/messages/did/%@/number/%@";

// SMS Message Blocking
NSString *const kJCV5ApiSMSMessageBlockedNumbersURLPath                = @"sms/blockedNumbers/did/%@";
NSString *const kJCV5ApiSMSMessageBlockURLPath                         = @"sms/block/did/%@/number/%@";
NSString *const kJCV5ApiSMSMessageUnblockURLPath                       = @"sms/unblock/did/%@/number/%@";

@implementation JCV5ApiClient (SMSMessaging)

#pragma mark - SMS Messages -

+ (void)sendSMSMessageWithParameters:(NSDictionary *)parameters completion:(JCApiClientCompletionHandler)completion
{
    [self postWithPath:kJCV5ApiSMSMessageSendRequestUrlPath
            parameters:parameters
     requestSerializer:[JCBearerAuthenticationJSONRequestSerializer new]
               retries:MESSAGES_SEND_NUMBER_OF_TRIES
            completion:completion];
}

+ (void)downloadMessagesDigestForDID:(DID *)did completion:(JCApiClientCompletionHandler)completion
{
    if (!did) {
        if (completion) {
            completion(NO, nil, [JCApiClientError errorWithCode:API_CLIENT_INVALID_ARGUMENTS reason:@"DID Is Null"]);
        }
        return;
    }
    
    NSString *path = [NSString stringWithFormat:kJCV5ApiSMSMessageRequestConversationsDigestURLPath, did.number];
    [self getWithPath:path
           parameters:nil
    requestSerializer:[JCBearerAuthenticationJSONRequestSerializer new]
              retries:CONVERSATIONS_DOWNLOAD_NUMBER_OF_TRIES
           completion:completion];
}

+ (void)downloadMessagesForDID:(DID *)did completion:(JCApiClientCompletionHandler)completion
{
    if (!did) {
        if (completion) {
            completion(NO, nil, [JCApiClientError errorWithCode:API_CLIENT_INVALID_ARGUMENTS reason:@"DID Is Null"]);
        }
        return;
    }
    
    
    NSString *path = [NSString stringWithFormat:kJCV5ApiSMSMessageRequestConversationsURLPath, did.number];
    [self getWithPath:path
           parameters:nil
    requestSerializer:[JCBearerAuthenticationJSONRequestSerializer new]
              retries:MESSAGES_DOWNLOAD_NUMBER_OF_TRIES
           completion:completion];
}

+ (void)downloadMessagesForDID:(DID *)did toConversationGroup:(id<JCConversationGroupObject>)conversationGroup completion:(JCApiClientCompletionHandler)completion
{
    if (!did) {
        if (completion) {
            completion(NO, nil, [JCApiClientError errorWithCode:API_CLIENT_INVALID_ARGUMENTS reason:@"DID Is Null"]);
        }
        return;
    }
    
    if (!conversationGroup) {
        if (completion) {
            completion(NO, nil, [JCApiClientError errorWithCode:API_CLIENT_INVALID_ARGUMENTS reason:@"Person Is Null"]);
        }
        return;
    }
    
    
    NSString *path = [NSString stringWithFormat:kJCV5ApiSMSMessageRequestConversationURLPath, did.number, conversationGroup.dialableNumber];
    [self getWithPath:path
           parameters:nil
    requestSerializer:[JCBearerAuthenticationJSONRequestSerializer new]
              retries:MESSAGES_DOWNLOAD_NUMBER_OF_TRIES
           completion:completion];
}

#pragma mark - SMS Message Blocking -

+ (void)blockSMSMessageForDID:(DID *)did
                       number:(id<JCPhoneNumberDataSource>)phoneNumber
                   completion:(JCApiClientCompletionHandler)completion
{
    NSString *path = [NSString stringWithFormat:kJCV5ApiSMSMessageBlockURLPath, did.number, phoneNumber.dialableNumber];
    [self postWithPath:path
            parameters:nil
     requestSerializer:[JCBearerAuthenticationJSONRequestSerializer new]
               retries:MESSAGES_UNBLOCK_NUMBER_OF_TRIES
            completion:completion];
}

+ (void)unblockSMSMessageForDID:(DID *)did
                         number:(id<JCPhoneNumberDataSource>)phoneNumber
                     completion:(JCApiClientCompletionHandler)completion
{
    NSString *path = [NSString stringWithFormat:kJCV5ApiSMSMessageUnblockURLPath, did.number, phoneNumber.dialableNumber];
    [self postWithPath:path
            parameters:nil
     requestSerializer:[JCBearerAuthenticationJSONRequestSerializer new]
               retries:MESSAGES_UNBLOCK_NUMBER_OF_TRIES
            completion:completion];
}

+ (void)downloadMessagesBlockedForDID:(DID *)did
                           completion:(JCApiClientCompletionHandler)completion
{
    NSString *path = [NSString stringWithFormat:kJCV5ApiSMSMessageBlockedNumbersURLPath, did.number];
    [self getWithPath:path
           parameters:nil
    requestSerializer:[JCBearerAuthenticationJSONRequestSerializer new]
              retries:MESSAGES_BLOCKED_NUMBER_DOWNLOAD_NUMBER_OF_TRIES
           completion:completion];
}


@end
