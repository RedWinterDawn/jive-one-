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

NSString *const kMessageRequestPathUrl          = @"/sms/sendSmsExternal";

NSString *const kMessageRequestToKey            = @"to";
NSString *const kMessageRequestFromKey          = @"from";
NSString *const kMessageRequestBodyKey          = @"body";

NSString *const kMessageResponseStatusKey       = @"status";
NSString *const kMessageResponseErrorMsgKey     = @"errorMessage";
NSString *const kMessageResponseErrorCodeKey    = @"errorCode";
NSString *const kMessageResponseObjectKey       = @"message";

NSString *const kMessageResponseObjectDidIdKey              = @"didId";
NSString *const kMessageResponseObjectNumberKey             = @"number";
NSString *const kMessageResponseObjectTextKey               = @"body";
NSString *const kMessageResponseObjectDirectionKey          = @"direction";
NSString *const kMessageResponseObjectDirectionInboundValue     = @"inbound";
NSString *const kMessageResponseObjectArrivalTimeKey        = @"arrivalTime";


NSString *const kMessageInvalidSendResponseException  = @"invalidSendResponse";


@implementation Message (SMSClient)

+(void)sendMessage:(NSString *)message
          toNumber:(NSString *)number
           fromDid:(DID *)did
        completion:(CompletionHandler)completion
{
    NSDictionary *parameters = @{kMessageRequestToKey:number,
                                 kMessageRequestFromKey: @"18013163336",  //did.didId,
                                 kMessageRequestBodyKey: message};
    
    [self sendMessageWithRetries:MESSAGES_SEND_NUMBER_OF_RETRIES
                      parameters:parameters
                         success:^(id responseObject) {
                             [self processSmsSendResponseObject:responseObject completion:completion];
                         }
                         failure:^(NSError *error) {
                             if (completion) {
                                 completion(NO, [JCClientError errorWithCode:JCClientRequestErrorCode userInfo:error.userInfo]);
                             }
                         }];
}

+(void)downloadMessagesForDid:(DID *)did completion:(CompletionHandler)completion
{
    
}

#pragma mark - Private -


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
        [client.manager POST:kMessageRequestPathUrl
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

+ (void)processSmsSendResponseObject:(id)responseObject completion:(CompletionHandler)completion
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @autoreleasepool {
            @try {
                // Is dictionary?
                if (![responseObject isKindOfClass:[NSDictionary class]]) {
                    [NSException raise:kMessageInvalidSendResponseException format:@"Dictionary is null"];
                }
                
                // Is Success?
                NSDictionary *response = (NSDictionary *)responseObject;
                NSInteger errorCode = [response integerValueForKey:kMessageResponseErrorCodeKey];
                if (errorCode != 0) {
                    if (completion) {
                        completion(false, [JCSMSClientError errorWithCode:errorCode]);
                    }
                    return;
                }
                
                // Do we have a response object?
                id object = [response objectForKey:kMessageResponseObjectKey];
                if(!object || ![object isKindOfClass:[NSDictionary class]]) {
                    [NSException raise:kMessageInvalidSendResponseException format:@"Response object is null or invalid"];
                }
                
                // Lets get a mamanged object context and create a message from the response object
                // and save it to the local store.
                [MagicalRecord saveUsingCurrentThreadContextWithBlock:^(NSManagedObjectContext *localContext) {
                    [self createSmsMessageWithMessageData:(NSDictionary *)object context:localContext];
                }
                                                           completion:^(BOOL success, NSError *error) {
                                                               if (completion) {
                                                                   if (error) {
                                                                       completion(NO, error);
                                                                   } else {
                                                                       completion(YES, nil);
                                                                   }
                                                               }
                                                           }];
            }
            @catch (NSException *exception) {
                NSInteger code;
                if (completion) {
                    if ([exception.name isEqualToString:kMessageInvalidSendResponseException]) {
                        code = SMS_RESPONSE_INVALID;
                    }
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completion(NO, [JCSMSClientError errorWithCode:code]);
                    });
                }
            }
        }
    });
}

+ (void)createSmsMessageWithMessageData:(NSDictionary *)data context:(NSManagedObjectContext *)context
{
    // Fetch values from data object.
    NSString *didId = [data stringValueForKey:kMessageResponseObjectDidIdKey];
    NSString *number = [data stringValueForKey:kMessageResponseObjectNumberKey];
    NSString *message = [data stringValueForKey:kMessageResponseObjectTextKey];
    NSString *direction = [data stringValueForKey:kMessageResponseObjectDirectionKey];
    NSDate *date = [data dateValueForKey:kMessageResponseObjectArrivalTimeKey];
    
    // Create message
    SMSMessage *smsMessage = [SMSMessage MR_createInContext:context];
    [smsMessage setDidId:didId];
    [smsMessage setNumber:number name:nil];
    smsMessage.text = message;
    smsMessage.inbound = [direction isEqualToString:kMessageResponseObjectDirectionInboundValue] ? true : false;
    smsMessage.date = date;
    smsMessage.read = TRUE;
}


@end
