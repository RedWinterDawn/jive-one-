//
//  Message+SMSClient.m
//  JiveOne
//
//  Created by P Leonard on 2/16/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "SMSMessage+SMSClient.h"
#import "JCSMSClient.h"

NSString *const kMessageRequestToKey = @"to";
NSString *const kMessageRequestFromKey = @"from";
NSString *const kMessageRequestBodyKey = @"body";
NSString *const kMessageResponseObjectKey = @"message";

NSString *const kMessageResponseStatusKey = @"status";
NSString *const kMessageResponseErrorMsgKey = @"errorMessage";
NSString *const kMessageResponseErrorCodeKey = @"errorCode";

NSString *const kMessageInvalidSendResponseException  = @"invalidSendResponse";

NSString *const kMessageResponseStatusSuccessValue = @"queued";
NSString *const kMessageResponseStatusFailureValue  = @"failure";

NSString *const kMessageRequestPathUrl = @"/sms/sendSmsExternal";

@implementation Message (SMSClient)

+(void)sendMessageForDID:(DID *)did person:(id<JCPerson>)person message:(NSString *)message completion:(CompletionHandler)completion
{
    NSDictionary *parameters = @{
                                 kMessageRequestToKey:person.number,
                                 kMessageRequestFromKey: @"18013163336",  //did.didId,
                                 kMessageRequestBodyKey: message};
    
    [self sendMessageWithRetries:1
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
     
+ (void)sendMessageWithRetries:(NSInteger)retryCount parameters:(NSDictionary *)parameters success:(void (^)(id responseObject))success failure:(void (^)(NSError *error))failure
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

+(void)processSmsSendResponseObject:(id)responseObject completion:(CompletionHandler)completion
{
    @try {
        // Is dictionary?
        if (![responseObject isKindOfClass:[NSDictionary class]]) {
            [NSException raise:kMessageInvalidSendResponseException format:@"dictionary is null"];
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
        
        id object = [response objectForKey:kMessageResponseObjectKey];
        if(!object || ![object isKindOfClass:[NSDictionary class]]) {
            [NSException raise:kMessageInvalidSendResponseException format:@"response object is null or invalid"];
        }
        
        NSDictionary *messageData = (NSDictionary *)object;
        
        // Process line configuration data response and store into core data, linking to our line.
        [MagicalRecord saveUsingCurrentThreadContextWithBlock:^(NSManagedObjectContext *localContext) {
            [self createSmsMessageWithMessageData:messageData context:localContext];
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
                completion(NO, [JCSMSError errorWithCode:code]);
            });
        }
    }
}

+(void)createSmsMessageWithMessageData:(NSDictionary *)data context:(NSManagedObjectContext *)context
{
    NSString *didId = [data stringValueForKey:@"didId"];
    NSString *number = [data stringValueForKey:@"number"];
    NSString *message = [data stringValueForKey:@"body"];
    NSString *direction = [data stringValueForKey:@"direction"];
    NSDate *date = [data dateValueForKey:@"arrivalTime"];
    
    SMSMessage *smsMessage = [SMSMessage MR_createInContext:context];
    [smsMessage setDidId:didId];
    [smsMessage setNumber:number name:nil];
    smsMessage.text = message;
    smsMessage.inbound = [direction isEqualToString:@"inbound"] ? true : false;
    smsMessage.date = date;
}


+(void)downloadMessagesForDid:(DID *)did completion:(CompletionHandler)completion
{
//    NSDictionary *parameters = @{kJCLineConfigurationRequestUsernameKey:line.pbx.user.jiveUserId,
//                                 kJCLineConfigurationRequestPbxIdKey:line.pbx.pbxId,
//                                 kJCLineConfigurationRequestExtensionKey: line.extension};
//    
//    [self downloadLineConfigurationForLine:line
//                                   retries:3
//                                parameters:parameters
//                                   success:^(id responseObject) {
//                                       [self processLineConfigurationResponseObject:responseObject line:line completion:completion];
//                                   }
//                                   failure:^(NSError *error) {
//                                       if (completion) {
//                                           completion(NO, [JCClientError errorWithCode:JCClientRequestErrorCode userInfo:error.userInfo]);
//                                       }
//                                   }];
}
@end
