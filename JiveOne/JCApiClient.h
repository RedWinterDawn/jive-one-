//
//  JCClient.h
//  JiveOne
//
//  Created by Robert Barclay on 1/5/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

@import Foundation;

#import <AFNetworking/AFNetworking.h>
#import "JCError.h"

typedef void(^JCApiClientCompletionHandler)(BOOL success, id response, NSError *error);

@interface JCApiClient : NSObject
{
    AFHTTPRequestOperationManager *_manager;
}

@property (nonatomic, strong) AFHTTPRequestOperationManager *manager;

-(instancetype)initWithBaseURL:(NSURL *)url;

+ (void)cancelAllOperations;

+(void)getWithPath:(NSString *)path
        parameters:(NSDictionary *)parameters
 requestSerializer:(AFHTTPRequestSerializer *)requestSerializer
           retries:(NSUInteger)retries
        completion:(JCApiClientCompletionHandler)completion;

+(void)putWithPath:(NSString *)path
        parameters:(NSDictionary *)parameters
 requestSerializer:(AFHTTPRequestSerializer *)requestSerializer
           retries:(NSUInteger)retries
        completion:(JCApiClientCompletionHandler)completion;

+(void)postWithPath:(NSString *)path
         parameters:(NSDictionary *)parameters
  requestSerializer:(AFHTTPRequestSerializer *)requestSerializer
            retries:(NSUInteger)retries
         completion:(JCApiClientCompletionHandler)completion;

+(void)deleteWithPath:(NSString *)path
           parameters:(NSDictionary *)parameters
    requestSerializer:(AFHTTPRequestSerializer *)requestSerializer
              retries:(NSUInteger)retries
           completion:(JCApiClientCompletionHandler)completion;

@end

#pragma mark Request Serialization

@interface JCAuthenticationJSONRequestSerializer : AFJSONRequestSerializer

@end

@interface JCBearerAuthenticationJSONRequestSerializer : JCAuthenticationJSONRequestSerializer

@end

@interface JCXmlRequestSerializer : AFHTTPRequestSerializer

@end

@interface JCAuthenticationXmlRequestSerializer : JCXmlRequestSerializer

@end

#pragma mark Response Serialization

@interface JCXMLParserResponseSerializer : AFHTTPResponseSerializer

@end

#pragma mark Error Handling

// Networking and reponse parsings.
#define API_CLIENT_UNKNOWN_ERROR                            1000
#define API_CLIENT_INVALID_ARGUMENTS                        1001
#define API_CLIENT_INVALID_REQUEST_PARAMETERS               1002
#define API_CLIENT_REQUEST_ERROR                            1003
#define API_CLIENT_RESPONSE_ERROR                           1004
#define API_CLIENT_RESPONSE_PARSER_ERROR                    1005
#define API_CLIENT_UNEXPECTED_RESPONSE_ERROR                1006
#define API_CLIENT_CORE_DATE_ERROR                          1007
#define API_CLIENT_AUTHENTICATION_ERROR                     1008
#define API_CLIENT_NETWORK_ERROR                            1009
#define API_CLIENT_TIMEOUT_ERROR                            1010
#define API_CLIENT_NO_PBX_ERROR                             1011

// Contacts

// PBXInfo

// Provisioning

// SMS
#define API_CLIENT_SMS_DOWNLOAD_REQUEST_FAILED             1100
#define API_CLIENT_SMS_RESPONSE_INVALID                    1100
#define API_CLIENT_SMS_FAILED_CODE_OAUTH                   1101
#define API_CLIENT_SMS_FAILED_CODE_USER_PERMISSION         1102
#define API_CLIENT_SMS_FAILED_CODE_NO_DID                  1103
#define API_CLIENT_SMS_FAILED_CODE_PBX_DISABLED            1104
#define API_CLIENT_SMS_FAILED_CODE_PEER_DISABLED           1105
#define API_CLIENT_SMS_MESSAGE_CAP_REACHED                 1111
#define API_CLIENT_SMS_MESSAGE_CAP_UNDEFINED               1112

// Voicemail

@interface JCApiClientError : JCError

@end

