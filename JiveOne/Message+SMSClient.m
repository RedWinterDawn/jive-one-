//
//  Message+SMSClient.m
//  JiveOne
//
//  Created by P Leonard on 2/16/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "Message+SMSClient.h"
#import "JCSMSClient.h"

NSString *const kMessageRequestToKey = @"to";
NSString *const kMessageRequestFromKey = @"from";
NSString *const kMessageRequestBodyKey = @"body";

NSString *const kMessageResponceStatusKey = @"status";
NSString *const kMessageResponceErrorMsgKey = @"errorMessage";
NSString *const kMessageResponceErrorCodeKey = @"errorCode";



NSString *const kMessageRequestPathUrl = @"/sendSmsExternal";

@implementation Message (SMSClient)

+(void)sendMessageForDID:(DID *)did user:(User *)user person:(id<JCPerson>)person message:(NSString *)message completion:(CompletionHandler)completion
{
    NSDictionary *parameters = @{
                                 kMessageRequestToKey:person.number,
                                 kMessageRequestFromKey:did.didId,
                                 kMessageRequestBodyKey: message};
    
    [self sendMessageForUser:user
                                    retries:1
                                     parameters:parameters
                                        success:^(id responseObject) {
                                           [self processSmsSendResponseObject:responseObject user:user completion:completion];
                                        }
                                        failure:^(NSError *error) {
                                            if (completion) {
                                                completion(NO, [JCClientError errorWithCode:JCClientRequestErrorCode userInfo:error.userInfo]);
                                            }
                                        }];
}
     
+ (void)sendMessageForUser:(User *)user retries:(NSInteger)retryCount parameters:(NSDictionary *)parameters success:(void (^)(id responseObject))success failure:(void (^)(NSError *error))failure
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
                             
                             [self sendMessageForUser:user retries:(retryCount - 1) parameters:parameters success:success failure:failure];
                         } else{
                             failure(error);
                         }
                     }];
    }
}

+(void)processSmsSendResponseObject:(id)responseObject user:(User *)user completion:(CompletionHandler)completion
{
    // Is dictionary?
    NSDictionary *status = [responseObject valueForKeyPath:kMessageResponceStatusKey];
    NSString *errorMessage = [responseObject valueForKey:kMessageResponceErrorMsgKey];
    
    // Is status set?
    if (status) {
        NSLog(@"You have a status");
    }
    
    // if status is failure, get error code.
    NSString *errorCode = [responseObject valueForKey:kMessageResponceErrorCodeKey];
    
    // if status not failure, create a message object from the response objects messgage object.

    Message *message;
    message.text = @"Doodle Do message for you";

    
//    NSInteger errorCode -> from JSON
//    
//    if (completion) {
//        completion(false,  [JCSMSClientError errorWithCode:errorCode])
//    }
    
   
    
    
}

+(void)downloadMessagesForUser:(User *)user completion:(CompletionHandler)completion
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
