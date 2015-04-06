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
                       retries:PBX_INFO_SEND_NUMBER_OF_TRIES
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
                       retries:MESSAGES_DOWNLOAD_NUMBER_OF_TRIES
                    completion:completion];
}

+ (void)downloadMessagesForDID:(DID *)did toPerson:(id<JCPersonDataSource>)person completion:(JCV5ApiClientCompletionHandler)completion
{
    if (!did) {
        if (completion) {
            completion(NO, nil, [JCApiClientError errorWithCode:API_CLIENT_INVALID_ARGUMENTS reason:@"DID Is Null"]);
        }
        return;
    }
    
    if (!person) {
        if (completion) {
            completion(NO, nil, [JCApiClientError errorWithCode:API_CLIENT_INVALID_ARGUMENTS reason:@"Person Is Null"]);
        }
        return;
    }
    
    
    NSString *path = [NSString stringWithFormat:kJCV5ApiSMSMessageRequestConversationURLPath, did.number, person.number];
    [JCV5ApiClient getWithPath:path
                    parameters:nil
                       retries:MESSAGES_DOWNLOAD_NUMBER_OF_TRIES
                    completion:completion];
}

#pragma - Private -

#pragma Retrying GETs

+(void)getWithPath:(NSString *)path
        parameters:(NSDictionary *)parameters
           retries:(NSUInteger)retries
        completion:(JCV5ApiClientCompletionHandler)completion
{
    [JCV5ApiClient getWithPath:path
                    parameters:parameters
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
        JCV5ApiClient *client = [JCV5ApiClient sharedClient];
        [client.manager GET:path
                 parameters:parameters
                    success:^(AFHTTPRequestOperation *operation, id responseObject) {
                        success(responseObject);
                    }
                    failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                        if (error.code == NSURLErrorTimedOut) {
                            NSLog(@"Retry %lu for post to path %@", (long)retryCount, path);
                            [self getWithPath:path parameters:parameters retries:(retryCount - 1) success:success failure:failure];
                        } else{
                            failure(error);
                        }
                    }];
    }
}

#pragma Retrying POSTs

+(void)postWithPath:(NSString *)path
         parameters:(NSDictionary *)parameters
            retries:(NSUInteger)retries
         completion:(JCV5ApiClientCompletionHandler)completion
{
    [JCV5ApiClient postWithPath:path
                     parameters:parameters
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

+(void)postWithPath:(NSString *)path
         parameters:(NSDictionary *)parameters
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
        JCV5ApiClient *client = [JCV5ApiClient sharedClient];
        [client.manager POST:path
                  parameters:parameters
                     success:^(AFHTTPRequestOperation *operation, id responseObject) {
                         success(responseObject);
                     }
                     failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                         if (error.code == NSURLErrorTimedOut) {
                             NSLog(@"Retry %lu for post to path %@", (long)retryCount, path);
                             [self getWithPath:path parameters:parameters retries:(retryCount - 1) success:success failure:failure];
                         } else{
                             failure(error);
                         }
                     }];
    }
}

@end
