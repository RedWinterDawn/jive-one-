//
//  Message+SMSClient.m
//  JiveOne
//
//  Created by P Leonard on 2/16/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "SMSMessage+SMSClient.h"
#import "JCSMSClient.h"

#ifndef MESSAGES_SEND_NUMBER_OF_RETRIES
#define MESSAGES_SEND_NUMBER_OF_RETRIES 1
#endif

#ifndef CONVERSATIONS_DOWNLOAD_NUMBER_OF_RETRIES
#define CONVERSATIONS_DOWNLOAD_NUMBER_OF_RETRIES 1
#endif

#ifndef MESSAGES_DOWNLOAD_NUMBER_OF_RETRIES
#define MESSAGES_DOWNLOAD_NUMBER_OF_RETRIES 1
#endif

NSString *const kSMSMessageSendRequestUrlPath                   = @"send";
NSString *const kSMSMessageRequestConversationsDigestURLPath    = @"digest/did/%@/";
NSString *const kSMSMessageRequestConversationsURLPath          = @"messages/did/%@";
NSString *const kSMSMessageRequestConversationURLPath           = @"messages/did/%@/number/%@";

NSString *const kSMSMessageSendRequestToKey                 = @"to";
NSString *const kSMSMessageSendRequestFromKey               = @"from";
NSString *const kSMSMessageSendRequestBodyKey               = @"body";

NSString *const kSMSMessageResponseStatusKey                = @"status";
NSString *const kSMSMessageResponseErrorMsgKey              = @"errorMessage";
NSString *const kSMSMessageResponseErrorCodeKey             = @"errorCode";
NSString *const kSMSMessageResponseObjectKey                = @"message";

NSString *const kSMSMessageResponseObjectDidIdKey              = @"didId";
NSString *const kSMSMessageResponseObjectNumberKey             = @"number";
NSString *const kSMSMessageResponseObjectTextKey               = @"body";
NSString *const kSMSMessageResponseObjectDirectionKey          = @"direction";
NSString *const kSMSMessageResponseObjectDirectionInboundValue     = @"inbound";
NSString *const kSMSMessageResponseObjectArrivalTimeKey        = @"arrivalTime";
NSString *const kSMSMessageResponseObjectHashKey               = @"hash";

NSString *const kSMSMessageInvalidSendResponseException = @"invalidSendResponse";

NSString *const kSMSMessageHashCreateString = @"%@-%@-%@-%@-%@";

@implementation SMSMessage (SMSClient)

+ (void)createSmsMessageWithMessageData:(NSDictionary *)data did:(DID *)did
{
    // Fetch values from data object.
    NSString *didId     = [data stringValueForKey:kSMSMessageResponseObjectDidIdKey];
    NSString *number    = [data stringValueForKey:kSMSMessageResponseObjectNumberKey];
    NSString *text      = [data stringValueForKey:kSMSMessageResponseObjectTextKey];
    NSString *direction = [data stringValueForKey:kSMSMessageResponseObjectDirectionKey];
    NSString *time      = [data stringValueForKey:kSMSMessageResponseObjectArrivalTimeKey];
    NSString *hash      = [data stringValueForKey:kSMSMessageResponseObjectHashKey];
    if (!hash) {
        hash = [NSString stringWithFormat:kSMSMessageHashCreateString, didId, number, text, direction, time].MD5Hash;
    }
    
    // We check to see if we already have a message using the stored server hash, and if we don't,
    // we create one with the data.
    SMSMessage *message = [SMSMessage MR_findFirstByAttribute:NSStringFromSelector(@selector(serverHash)) withValue:hash inContext:did.managedObjectContext];
    if (!message) {
        message = [SMSMessage MR_createInContext:did.managedObjectContext];
        message.serverHash = hash;
        [message setNumber:number name:nil];
        message.text = text;
        message.inbound = [direction isEqualToString:kSMSMessageResponseObjectDirectionInboundValue] ? true : false;
        message.read = [direction isEqualToString:kSMSMessageResponseObjectDirectionInboundValue] ? false : true;
        message.date = [data datetimeValueForKey:kSMSMessageResponseObjectArrivalTimeKey];
        message.did = did;
    }
}

#pragma mark - Send -

+(void)sendMessage:(NSString *)message toPerson:(id<JCPersonDataSource>)person fromDid:(DID *)did completion:(CompletionHandler)completion
{
    NSDictionary *parameters = @{kSMSMessageSendRequestToKey: person.number,
                                 kSMSMessageSendRequestFromKey: did.didId,
                                 kSMSMessageSendRequestBodyKey: message};
    
    [self sendMessageWithRetries:MESSAGES_SEND_NUMBER_OF_RETRIES
                      parameters:parameters
                         success:^(id responseObject) {
                             [self processSMSSendResponseObject:responseObject did:did completion:completion];
                         }
                         failure:^(NSError *error) {
                             if (completion) {
                                 completion(NO, [JCClientError errorWithCode:JCClientRequestErrorCode userInfo:error.userInfo]);
                             }
                         }];
}

#pragma mark - Receive -

+(void)downloadMessagesForDIDs:(NSSet *)dids completion:(CompletionHandler)completion
{
    __block NSError *batchError;
    __block NSMutableSet *pendingDids = [NSMutableSet setWithSet:dids];
    for (id object in dids) {
        if ([object isKindOfClass:[DID class]]) {
            __block DID *did = (DID *)object;
            [self downloadMessagesForDID:did completion:^(BOOL success, NSError *error) {
                if (error && !batchError) {
                    batchError = error;
                }
                
                [pendingDids removeObject:did];
                if (pendingDids.count == 0) {
                    if (completion) {
                        completion((error == nil), batchError );
                    }
                }
            }];
        }
    }
}

+(void)downloadMessagesForDID:(DID *)did completion:(CompletionHandler)completion
{
    [self downloadMessagesForDID:did
                         retries:CONVERSATIONS_DOWNLOAD_NUMBER_OF_RETRIES
                         success:^(id responseObject) {
                             [self processSMSDownloadConversationsResponseObject:responseObject completion:completion];
                         }
                         failure:^(NSError *error) {
                             if (completion) {
                                 completion(NO, [JCClientError errorWithCode:JCClientRequestErrorCode userInfo:error.userInfo]);
                             }
                         }];
}

+(void)downloadMessagesForDID:(DID *)did toPerson:(id<JCPersonDataSource>)person completion:(CompletionHandler)completion
{
    [self downloadMessagesForDID:did
                          person:person
                         retries:MESSAGES_DOWNLOAD_NUMBER_OF_RETRIES
                         success:^(id responseObject) {
                             [self processSMSDownloadConversationResponseObject:responseObject did:did completion:completion];
                         }
                         failure:^(NSError *error) {
                             if (completion) {
                                 completion(NO, [JCClientError errorWithCode:JCClientRequestErrorCode userInfo:error.userInfo]);
                             }
                         }];
}

#pragma mark - Private -

#pragma mark Retries

// These private methods implement a model suggested by AFNetworking for how to implement retry
// behavior whilst using thier library to perform network requests. While AFNetworking does not have
// specific logic for retrys, it is left to the developer to implement. Each request has a specific
// configuable number of retires. It will retry unti the retry count equals 0, and then call
// completion with failure error code.

+ (void)sendMessageWithRetries:(NSInteger)retryCount
                    parameters:(NSDictionary *)parameters
                       success:(void (^)(id responseObject))success
                       failure:(void (^)(NSError *error))failure
{
    if (retryCount <= 0) {
        if (failure) {
            NSError *error = [JCClientError errorWithCode:JCClientRequestErrorCode reason:@"Request Timeout"];
            failure(error);
        }
    } else {
        JCSMSClient *client = [[JCSMSClient alloc] init];
        [client.manager POST:kSMSMessageSendRequestUrlPath
                  parameters:parameters
                     success:^(AFHTTPRequestOperation *operation, id responseObject) {
                         success(responseObject);
                     }
                     failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                         if (error.code == NSURLErrorTimedOut) {
                             NSLog(@"Retry Message send: %lu", (long)retryCount);
                             [self sendMessageWithRetries:(retryCount - 1) parameters:parameters success:success failure:failure];
                         } else{
                             failure(error);
                         }
                     }];
    }
}

+ (void)downloadMessagesForDID:(DID *)did
                       retries:(NSInteger)retryCount
                       success:(void (^)(id responseObject))success
                       failure:(void (^)(NSError *error))failure
{
    if (retryCount <= 0) {
        if (failure) {
            NSError *error = [JCClientError errorWithCode:JCClientRequestErrorCode reason:@"Request Timeout"];
            failure(error);
        }
    } else {
        NSString *path = [NSString stringWithFormat:kSMSMessageRequestConversationsDigestURLPath, did.number];
        JCSMSClient *client = [[JCSMSClient alloc] init];
        [client.manager GET:path
                 parameters:nil
                    success:^(AFHTTPRequestOperation *operation, id responseObject) {
                        success(responseObject);
                    }
                    failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                        if (error.code == NSURLErrorTimedOut) {
                            NSLog(@"Retry conversations download: %lu for did: %@", (long)retryCount, did.didId);
                            [self downloadMessagesForDID:did retries:(retryCount - 1) success:success failure:failure];
                        } else{
                            failure(error);
                        }
                    }];
    }
}

+ (void)downloadMessagesForDID:(DID *)did
                        person:(id<JCPersonDataSource>)person
                       retries:(NSInteger)retryCount
                       success:(void (^)(id responseObject))success
                       failure:(void (^)(NSError *error))failure
{
    if (retryCount <= 0) {
        if (failure) {
            NSError *error = [JCClientError errorWithCode:JCClientRequestErrorCode reason:@"Request Timeout"];
            failure(error);
        }
    } else {
        NSString *path = [NSString stringWithFormat:kSMSMessageRequestConversationURLPath, did.number, person.number];
        JCSMSClient *client = [[JCSMSClient alloc] init];
        [client.manager GET:path
                 parameters:nil
                    success:^(AFHTTPRequestOperation *operation, id responseObject) {
                        success(responseObject);
                    }
                    failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                        if (error.code == NSURLErrorTimedOut) {
                            NSLog(@"Retry Message send: %lu", (long)retryCount);
                            [self downloadMessagesForDID:did person:person retries:(retryCount - 1) success:success failure:failure];
                        } else{
                            failure(error);
                        }
                    }];
    }
}

#pragma Response Processing

// The send sms logic does not actually create the core data object until we have gotten a positive
// confimation from the server that the message was sent. When we process the result, we build the
// message from the result and store it locally
+ (void)processSMSSendResponseObject:(id)responseObject did:(DID *)did completion:(CompletionHandler)completion
{
    @try {
        // Is dictionary?
        if (![responseObject isKindOfClass:[NSDictionary class]]) {
            [NSException raise:kSMSMessageInvalidSendResponseException format:@"Dictionary is null"];
        }
        
        // Is Success?
        NSDictionary *response = (NSDictionary *)responseObject;
        NSInteger errorCode = [response integerValueForKey:kSMSMessageResponseErrorCodeKey];
        if (errorCode != 0) {
            if (completion) {
                completion(false, [JCSMSClientError errorWithCode:errorCode]);
            }
            return;
        }
        
        // Do we have a response object?
        id object = [response objectForKey:kSMSMessageResponseObjectKey];
        if(!object || ![object isKindOfClass:[NSDictionary class]]) {
            [NSException raise:kSMSMessageInvalidSendResponseException format:@"Response object is null or invalid"];
        }
        
        [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
            DID *localDid = (DID *)[localContext objectWithID:did.objectID];
            [self createSmsMessageWithMessageData:(NSDictionary *)object did:localDid];
        } completion:completion];
    }
    @catch (NSException *exception) {
        NSInteger code;
        if (completion) {
            if ([exception.name isEqualToString:kSMSMessageInvalidSendResponseException]) {
                code = SMS_RESPONSE_INVALID;
            }
            completion(NO, [JCSMSClientError errorWithCode:code]);
        }
    }
}

+ (void)processSMSDownloadConversationsResponseObject:(id)responseObject completion:(CompletionHandler)completion
{
    @try {
        
        // Is Array? We should have an array of messages.
        if (![responseObject isKindOfClass:[NSArray class]]) {
            [NSException raise:kSMSMessageInvalidSendResponseException format:@"Array is null"];
        }
        
        NSLog(@"%@", responseObject);
        
        [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
            
            // TODO: Implement this.
            
        } completion:completion];
    }
    @catch (NSException *exception) {
        NSInteger code;
        if (completion) {
            if ([exception.name isEqualToString:kSMSMessageInvalidSendResponseException]) {
                code = SMS_RESPONSE_INVALID;
            }
            completion(NO, [JCSMSClientError errorWithCode:code]);
        }
    }
}

+ (void)processSMSDownloadConversationResponseObject:(id)responseObject did:(DID *)did completion:(CompletionHandler)completion
{
    @try {
        
        // Is Array? We should have an array of messages.
        if (![responseObject isKindOfClass:[NSArray class]]) {
            [NSException raise:kSMSMessageInvalidSendResponseException format:@"Array is null"];
        }
        
        NSArray *messages = (NSArray *)responseObject;
        [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
            DID *localDid = did ? (DID *)[localContext objectWithID:did.objectID] : nil;
            for (id object in messages) {
                if ([object isKindOfClass:[NSDictionary class]]) {
                    [self createSmsMessageWithMessageData:(NSDictionary *)object did:localDid];
                }
            }
        }
        completion:completion];
    }
    @catch (NSException *exception) {
        NSInteger code;
        if (completion) {
            if ([exception.name isEqualToString:kSMSMessageInvalidSendResponseException]) {
                code = SMS_RESPONSE_INVALID;
            }
            completion(NO, [JCSMSClientError errorWithCode:code]);
        }
    }
}

#pragma mark Shared



@end
