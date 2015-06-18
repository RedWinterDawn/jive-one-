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

+ (void)requestPBXInforForUser:(User *)user competion:(JCV5ApiClientCompletionHandler)completion
{
    if (!user) {
        if (completion) {
            completion(NO, nil, [JCApiClientError errorWithCode:API_CLIENT_INVALID_ARGUMENTS reason:@"User Is Null"]);
        }
        return;
    }
    
    NSString *path = [NSString stringWithFormat:kJCV5ApiPBXInfoRequestPath, user.jiveUserId];
    [JCV5ApiClient getWithPath:path
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

+ (void)downloadInternalExtensionsForLine:(Line *)line completion:(JCV5ApiClientCompletionHandler)completion
{
    if (!line) {
        if (completion) {
            completion(NO, nil, [JCApiClientError errorWithCode:API_CLIENT_INVALID_ARGUMENTS reason:@"Line Is Null"]);
        }
        return;
    }
    
    NSString *path = [NSString stringWithFormat:kJCV5ApiExtensionsRequestPath, line.pbx.pbxId, line.lineId];
    [JCV5ApiClient getWithPath:path
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

+ (void)downloadContactsWithCompletion:(JCV5ApiClientCompletionHandler)completion
{
    [JCV5ApiClient getWithPath:kJCV5ApiContactsDownloadRequestPath
                    parameters:nil
             requestSerializer:[JCBearerAuthenticationJSONRequestSerializer new]
                       retries:GET_CONTACTS_NUMBER_OF_TRIES
                    completion:completion];
}

+ (void)downloadContact:(Contact *)contact completion:(JCV5ApiClientCompletionHandler)completion
{
    if (!contact) {
        if (completion) {
            completion(NO, nil, [JCApiClientError errorWithCode:API_CLIENT_INVALID_ARGUMENTS reason:@"Contact Is Null"]);
        }
        return;
    }
    
    NSString *path = [NSString stringWithFormat:kJCV5ApiContactDownloadRequestPath, contact.contactId];
    [JCV5ApiClient getWithPath:path
                    parameters:nil
             requestSerializer:[JCBearerAuthenticationJSONRequestSerializer new]
                       retries:GET_CONTACTS_NUMBER_OF_TRIES
                    completion:completion];
}

+ (void)uploadContact:(Contact *)contact completion:(JCV5ApiClientCompletionHandler)completion
{
    if (!contact) {
        if (completion) {
            completion(NO, nil, [JCApiClientError errorWithCode:API_CLIENT_INVALID_ARGUMENTS reason:@"Contact Is Null"]);
        }
        return;
    }
    
    
    NSDictionary *serializedData = contact.serializedData;
    if (!contact.contactId) {
        [JCV5ApiClient postWithPath:kJCV5ApiContactUploadRequestPath
                         parameters:serializedData
                  requestSerializer:[JCBearerAuthenticationJSONRequestSerializer new]
                            retries:UPLOAD_CONTACT_NUMBER_OF_TRIES
                         completion:completion];
    }
    else {
        [JCV5ApiClient putWithPath:kJCV5ApiContactUploadRequestPath
                        parameters:serializedData
                 requestSerializer:[JCBearerAuthenticationJSONRequestSerializer new]
                           retries:UPLOAD_CONTACT_NUMBER_OF_TRIES
                        completion:completion];
    }
}

+ (void)deleteContact:(Contact *)contact conpletion:(JCV5ApiClientCompletionHandler)completion
{
    if (!contact) {
        if (completion) {
            completion(NO, nil, [JCApiClientError errorWithCode:API_CLIENT_INVALID_ARGUMENTS reason:@"Contact Is Null"]);
        }
        return;
    }
    
    NSString *path = [NSString stringWithFormat:kJCV5ApiContactDownloadRequestPath, contact.contactId];
    [JCV5ApiClient deleteWithPath:path
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

+ (void)sendSMSMessageWithParameters:(NSDictionary *)parameters completion:(JCV5ApiClientCompletionHandler)completion
{
    [JCV5ApiClient postWithPath:kJCV5ApiSMSMessageSendRequestUrlPath
                     parameters:parameters
              requestSerializer:nil
                        retries:MESSAGES_SEND_NUMBER_OF_TRIES
                     completion:completion];
}

+ (void)downloadMessagesDigestForDID:(DID *)did completion:(JCV5ApiClientCompletionHandler)completion
{
    if (!did) {
        if (completion) {
            completion(NO, nil, [JCApiClientError errorWithCode:API_CLIENT_INVALID_ARGUMENTS reason:@"DID Is Null"]);
        }
        return;
    }
    
    NSString *path = [NSString stringWithFormat:kJCV5ApiSMSMessageRequestConversationsDigestURLPath, did.number];
    [JCV5ApiClient getWithPath:path
                    parameters:nil
             requestSerializer:nil
                       retries:CONVERSATIONS_DOWNLOAD_NUMBER_OF_TRIES
                    completion:completion];
}

+ (void)downloadMessagesForDID:(DID *)did completion:(JCV5ApiClientCompletionHandler)completion
{
    if (!did) {
        if (completion) {
            completion(NO, nil, [JCApiClientError errorWithCode:API_CLIENT_INVALID_ARGUMENTS reason:@"DID Is Null"]);
        }
        return;
    }
    
    
    NSString *path = [NSString stringWithFormat:kJCV5ApiSMSMessageRequestConversationsURLPath, did.number];
    [JCV5ApiClient getWithPath:path
                    parameters:nil
             requestSerializer:nil
                       retries:MESSAGES_DOWNLOAD_NUMBER_OF_TRIES
                    completion:completion];
}

+ (void)downloadMessagesForDID:(DID *)did toConversationGroup:(id<JCConversationGroupObject>)conversationGroup completion:(JCV5ApiClientCompletionHandler)completion
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
    [JCV5ApiClient getWithPath:path
                    parameters:nil
             requestSerializer:nil
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
                   completion:(JCV5ApiClientCompletionHandler)completion
{
    NSString *path = [NSString stringWithFormat:kJCV5ApiSMSMessageBlockURLPath, did.number, phoneNumber.dialableNumber];
    [JCV5ApiClient postWithPath:path
                     parameters:nil
              requestSerializer:nil
                        retries:MESSAGES_UNBLOCK_NUMBER_OF_TRIES
                     completion:completion];
}

+ (void)unblockSMSMessageForDID:(DID *)did
                         number:(id<JCPhoneNumberDataSource>)phoneNumber
                     completion:(JCV5ApiClientCompletionHandler)completion
{
    NSString *path = [NSString stringWithFormat:kJCV5ApiSMSMessageUnblockURLPath, did.number, phoneNumber.dialableNumber];
    [JCV5ApiClient postWithPath:path
                     parameters:nil
              requestSerializer:nil
                        retries:MESSAGES_UNBLOCK_NUMBER_OF_TRIES
                     completion:completion];
}

+ (void)downloadMessagesBlockedForDID:(DID *)did
                           completion:(JCV5ApiClientCompletionHandler)completion
{
    NSString *path = [NSString stringWithFormat:kJCV5ApiSMSMessageBlockedNumbersURLPath, did.number];
    [JCV5ApiClient getWithPath:path
                    parameters:nil
             requestSerializer:nil
                       retries:MESSAGES_BLOCKED_NUMBER_DOWNLOAD_NUMBER_OF_TRIES
                    completion:completion];
}

#pragma mark - Private -

#pragma mark Retrying GETs

+(void)getWithPath:(NSString *)path
        parameters:(NSDictionary *)parameters
 requestSerializer:(AFJSONRequestSerializer *)requestSerializer
           retries:(NSUInteger)retries
        completion:(JCV5ApiClientCompletionHandler)completion
{
    [JCV5ApiClient getWithPath:path
                    parameters:parameters
             requestSerializer:requestSerializer
                       retries:retries
                       success:^(id responseObject) {
                           if (completion) {
                               completion(YES, responseObject, nil);
                           };
                       }
                       failure:^(NSError *error) {
                           if (completion) {
                               completion(NO, nil, [JCApiClientError errorWithCode:API_CLIENT_REQUEST_ERROR underlyingError:error]);
                           }
                       }];
}

+(void)getWithPath:(NSString *)path
        parameters:(NSDictionary *)parameters
 requestSerializer:(AFJSONRequestSerializer *)requestSerializer
           retries:(NSUInteger)retryCount
           success:(void (^)(id responseObject))success
           failure:(void (^)(NSError *error))failure
{
    if (retryCount <= 0) {
        if (failure) {
            NSError *error = [JCApiClientError errorWithCode:API_CLIENT_TIMEOUT_ERROR reason:@"Request Timeout"];
            failure(error);
        }
    } else {
        JCV5ApiClient *client = [JCV5ApiClient new];
        if (requestSerializer) {
            client.manager.requestSerializer = requestSerializer;
        }
        
        [client.manager GET:path
                 parameters:parameters
                    success:^(AFHTTPRequestOperation *operation, id responseObject) {
                        success(responseObject);
                    }
                    failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                        if (error.code == NSURLErrorTimedOut) {
                            NSLog(@"Retry %lu for post to path %@", (long)retryCount, path);
                            [self getWithPath:path
                                   parameters:parameters
                            requestSerializer:requestSerializer
                                      retries:(retryCount - 1)
                                      success:success
                                      failure:failure];
                        } else{
                            failure(error);
                        }
                    }];
    }
}

#pragma mark Retrying PUTS

+(void)putWithPath:(NSString *)path
        parameters:(NSDictionary *)parameters
 requestSerializer:(AFJSONRequestSerializer *)requestSerializer
           retries:(NSUInteger)retries
        completion:(JCV5ApiClientCompletionHandler)completion
{
    [self putWithPath:path
           parameters:parameters
    requestSerializer:requestSerializer
              retries:retries
              success:^(id responseObject) {
                  if (completion) {
                      completion(YES, responseObject, nil);
                  };
              }
              failure:^(id responseObject, NSError *error) {
                  if (completion) {
                      completion(NO, responseObject, [JCApiClientError errorWithCode:API_CLIENT_REQUEST_ERROR underlyingError:error]);
                  }
              }];
}

+(void)putWithPath:(NSString *)path
        parameters:(NSDictionary *)parameters
 requestSerializer:(AFJSONRequestSerializer *)requestSerializer
           retries:(NSUInteger)retryCount
           success:(void (^)(id responseObject))success
           failure:(void (^)(id responseObject, NSError *error))failure
{
    if (retryCount <= 0) {
        if (failure) {
            NSError *error = [JCApiClientError errorWithCode:API_CLIENT_TIMEOUT_ERROR reason:@"Request Timeout"];
            failure(nil, error);
        }
    } else {
        JCV5ApiClient *client = [JCV5ApiClient new];
        if (requestSerializer) {
            client.manager.requestSerializer = requestSerializer;
        }
        
        [client.manager PUT:path
                 parameters:parameters
                    success:^(AFHTTPRequestOperation *operation, id responseObject) {
                        success(responseObject);
                    }
                    failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                        if (error.code == NSURLErrorTimedOut) {
                            NSLog(@"Retry %lu for post to path %@", (long)retryCount, path);
                            [self putWithPath:path
                                   parameters:parameters
                            requestSerializer:requestSerializer
                                      retries:(retryCount - 1)
                                      success:success
                                      failure:failure];
                        } else {
                            failure(operation.responseObject, error);
                        }
                    }];
    }
}

#pragma mark Retrying POSTs

+(void)postWithPath:(NSString *)path
         parameters:(NSDictionary *)parameters
  requestSerializer:(AFJSONRequestSerializer *)requestSerializer
            retries:(NSUInteger)retries
         completion:(JCV5ApiClientCompletionHandler)completion
{
    [JCV5ApiClient postWithPath:path
                     parameters:parameters
              requestSerializer:requestSerializer
                        retries:retries
                        success:^(id responseObject) {
                            if (completion) {
                                completion(YES, responseObject, nil);
                            };
                        }
                        failure:^(id responseObject, NSError *error) {
                            if (completion) {
                                completion(NO, responseObject, [JCApiClientError errorWithCode:API_CLIENT_REQUEST_ERROR underlyingError:error]);
                            }
                        }];
}

+(void)postWithPath:(NSString *)path
         parameters:(NSDictionary *)parameters
  requestSerializer:(AFJSONRequestSerializer *)requestSerializer
            retries:(NSUInteger)retryCount
            success:(void (^)(id responseObject))success
            failure:(void (^)(id responseObject, NSError *error))failure
{
    if (retryCount <= 0) {
        if (failure) {
            NSError *error = [JCApiClientError errorWithCode:API_CLIENT_TIMEOUT_ERROR reason:@"Request Timeout"];
            failure(nil, error);
        }
    } else {
        JCV5ApiClient *client = [JCV5ApiClient new];
        if (requestSerializer) {
            client.manager.requestSerializer = requestSerializer;
        }
        
        [client.manager POST:path
                  parameters:parameters
                     success:^(AFHTTPRequestOperation *operation, id responseObject) {
                         success(responseObject);
                     }
                     failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                         if (error.code == NSURLErrorTimedOut) {
                             NSLog(@"Retry %lu for post to path %@", (long)retryCount, path);
                             [self postWithPath:path
                                     parameters:parameters
                              requestSerializer:requestSerializer
                                        retries:(retryCount - 1)
                                        success:success
                                        failure:failure];
                         } else{
                             failure(operation.responseObject, error);
                         }
                     }];
    }
}

#pragma mark Retrying DELETES

+(void)deleteWithPath:(NSString *)path
           parameters:(NSDictionary *)parameters
    requestSerializer:(AFJSONRequestSerializer *)requestSerializer
              retries:(NSUInteger)retries
           completion:(JCV5ApiClientCompletionHandler)completion
{
    [self deleteWithPath:path
              parameters:parameters
       requestSerializer:requestSerializer
                 retries:retries
                 success:^(id responseObject) {
                     if (completion) {
                         completion(YES, responseObject, nil);
                     };
                 }
                 failure:^(NSError *error) {
                     if (completion) {
                         completion(NO, nil, [JCApiClientError errorWithCode:API_CLIENT_REQUEST_ERROR underlyingError:error]);
                     }
                 }];
}

+(void)deleteWithPath:(NSString *)path
         parameters:(NSDictionary *)parameters
  requestSerializer:(AFJSONRequestSerializer *)requestSerializer
            retries:(NSUInteger)retryCount
            success:(void (^)(id responseObject))success
            failure:(void (^)(NSError *error))failure
{
    if (retryCount <= 0) {
        if (failure) {
            NSError *error = [JCApiClientError errorWithCode:API_CLIENT_TIMEOUT_ERROR reason:@"Request Timeout"];
            failure(error);
        }
    } else {
        JCV5ApiClient *client = [JCV5ApiClient new];
        if (requestSerializer) {
            client.manager.requestSerializer = requestSerializer;
        }
        
        [client.manager DELETE:path
                  parameters:parameters
                     success:^(AFHTTPRequestOperation *operation, id responseObject) {
                         success(responseObject);
                     }
                     failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                         if (error.code == NSURLErrorTimedOut) {
                             NSLog(@"Retry %lu for post to path %@", (long)retryCount, path);
                             [self deleteWithPath:path
                                       parameters:parameters
                                requestSerializer:requestSerializer
                                          retries:(retryCount - 1)
                                          success:success
                                          failure:failure];
                         } else{
                             failure(error);
                         }
                     }];
    }
}

@end
