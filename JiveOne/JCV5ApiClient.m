//
//  JCV5ApiClient.m
//  JiveOne
//
//  Created by Eduardo Gueiros on 10/2/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCV5ApiClient.h"
#import "Common.h"
#import "Voicemail.h"
#import "User.h"
#import "DID.h"
#import "Contact+V5Client.h"
#import "PBX.h"
#import "Line.h"
#import "JCAuthenticationManager.h"

NSString *const kJCV5ApiClientBaseUrl = @"https://api.jive.com/";

@implementation JCV5ApiClient

#pragma mark - class methods

+ (instancetype)sharedClient {
	static JCV5ApiClient *sharedClient = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedClient = [super new];
	});
	return sharedClient;
}

-(instancetype)init
{
    NSURL *url = [NSURL URLWithString:kJCV5ApiClientBaseUrl];
    return [self initWithBaseURL:url];
}

-(instancetype)initWithBaseURL:(NSURL *)url {
    self = [super initWithBaseURL:url];
    if (self) {
        _manager.requestSerializer = [JCAuthenticationJSONRequestSerializer serializer];
        _manager.responseSerializer = [AFJSONResponseSerializer serializer];
    }
    return self;
}

- (BOOL)isOperationRunning:(NSString *)operationName
{
	NSArray *operations = [_manager.operationQueue operations];
	for (AFHTTPRequestOperation *op in operations) {
		if ([op.name isEqualToString:operationName]) {
			return op.isExecuting;
		}
	}
	return NO;
}

#pragma mark - PBX Info -

#ifndef PBX_INFO_NUMBER_OF_TRIES
#define PBX_INFO_SEND_NUMBER_OF_TRIES 1
#endif

NSString *const kJCV5ApiPBXInfoRequestPath = @"/jif/v3/user/jiveId/%@";

+ (void)requestPBXInforForUser:(User *)user competion:(JCApiClientCompletionHandler)completion
{
    if (!user) {
        if (completion) {
            completion(NO, nil, [JCApiClientError errorWithCode:API_CLIENT_INVALID_ARGUMENTS reason:@"User Is Null"]);
        }
        return;
    }
    
    NSString *path = [NSString stringWithFormat:kJCV5ApiPBXInfoRequestPath, user.jiveUserId];
    [self getWithPath:path
           parameters:nil
    requestSerializer:[JCBearerAuthenticationJSONRequestSerializer new]
              retries:PBX_INFO_SEND_NUMBER_OF_TRIES
           completion:completion];
}

#pragma mark - Internal Contacts -

#ifndef GET_EXTENSIONS_NUMBER_OF_TRIES
#define GET_EXTENSIONS_NUMBER_OF_TRIES 1
#endif

NSString *const kJCV5ApiExtensionsRequestPath = @"/contacts/2014-07/%@/line/id/%@";

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
    requestSerializer:[JCBearerAuthenticationJSONRequestSerializer new]
              retries:GET_EXTENSIONS_NUMBER_OF_TRIES
           completion:completion];
}

#pragma mark - Contacts -

#ifndef GET_CONTACTS_NUMBER_OF_TRIES
#define GET_CONTACTS_NUMBER_OF_TRIES 1
#endif

#ifndef UPLOAD_CONTACT_NUMBER_OF_TRIES
#define UPLOAD_CONTACT_NUMBER_OF_TRIES 1
#endif

#ifndef DELETE_CONTACT_NUMBER_OF_TRIES
#define DELETE_CONTACT_NUMBER_OF_TRIES 1
#endif

NSString *const kJCV5ApiContactsDownloadRequestPath = @"/contacts/v3/user/contacts";
NSString *const kJCV5ApiContactDownloadRequestPath  = @"/contacts/v3/user/contact/%@";
NSString *const kJCV5ApiContactUploadRequestPath    = @"/contacts/v3/user/contact";

+ (void)downloadContactsWithCompletion:(JCApiClientCompletionHandler)completion
{
    [self getWithPath:kJCV5ApiContactsDownloadRequestPath
           parameters:nil
    requestSerializer:[JCBearerAuthenticationJSONRequestSerializer new]
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
    requestSerializer:[JCBearerAuthenticationJSONRequestSerializer new]
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
       requestSerializer:[JCBearerAuthenticationJSONRequestSerializer new]
                 retries:DELETE_CONTACT_NUMBER_OF_TRIES
              completion:completion];
}

#pragma mark - SMS Messaging -

#ifndef MESSAGES_SEND_NUMBER_OF_TRIES
#define MESSAGES_SEND_NUMBER_OF_TRIES 1
#endif

#ifndef CONVERSATIONS_DOWNLOAD_NUMBER_OF_TRIES
#define CONVERSATIONS_DOWNLOAD_NUMBER_OF_TRIES 1
#endif

#ifndef MESSAGES_DOWNLOAD_NUMBER_OF_TRIES
#define MESSAGES_DOWNLOAD_NUMBER_OF_TRIES 1
#endif

NSString *const kJCV5ApiSMSMessageSendRequestUrlPath                   = @"sms/send";
NSString *const kJCV5ApiSMSMessageRequestConversationsDigestURLPath    = @"sms/digest/did/%@/";
NSString *const kJCV5ApiSMSMessageRequestConversationsURLPath          = @"sms/messages/did/%@";
NSString *const kJCV5ApiSMSMessageRequestConversationURLPath           = @"sms/messages/did/%@/number/%@";

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

#ifndef MESSAGES_BLOCK_NUMBER_OF_TRIES
#define MESSAGES_BLOCK_NUMBER_OF_TRIES 1
#endif

#ifndef MESSAGES_UNBLOCK_NUMBER_OF_TRIES
#define MESSAGES_UNBLOCK_NUMBER_OF_TRIES 1
#endif

#ifndef MESSAGES_BLOCKED_NUMBER_DOWNLOAD_NUMBER_OF_TRIES
#define MESSAGES_BLOCKED_NUMBER_DOWNLOAD_NUMBER_OF_TRIES 1
#endif

NSString *const kJCV5ApiSMSMessageBlockedNumbersURLPath                = @"sms/blockedNumbers/did/%@";
NSString *const kJCV5ApiSMSMessageBlockURLPath                         = @"sms/block/did/%@/number/%@";
NSString *const kJCV5ApiSMSMessageUnblockURLPath                       = @"sms/unblock/did/%@/number/%@";

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
