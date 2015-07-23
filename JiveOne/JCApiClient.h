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

typedef enum : NSUInteger {
    JCApiClientGet,
    JCApiClientPut,
    JCApiClientPost,
    JCApiClientDelete
} JCApiClientCrudOperationType;

typedef void(^JCApiClientCompletionHandler)(BOOL success, id response, NSError *error);

@interface JCApiClient : NSObject
{
    AFHTTPRequestOperationManager *_manager;
}

@property (nonatomic, strong) AFHTTPRequestOperationManager *manager;

-(instancetype)initWithBaseURL:(NSURL *)url;

-(void)requestWithType:(JCApiClientCrudOperationType)type
                  path:(NSString *)path
            parameters:(NSDictionary *)parameters
     requestSerializer:(AFHTTPRequestSerializer *)requestSerializer
    responceSerializer:(AFHTTPResponseSerializer *)responceSerializer
               retries:(NSUInteger)retryCount
               success:(void (^)(id responseObject))success
               failure:(void (^)(id responseObject, NSError *error))failure;

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


typedef NS_ENUM(NSInteger, JCHTTPStatusCodes) {
    // Informational
    JCHTTPStatusCodeInformationalUnknown = 1,
    JCHTTPStatusCodeContinue = 100,
    JCHTTPStatusCodeSwitchingProtocols = 101,
    JCHTTPStatusCodeProcessing = 102,
    
    // Success
    JCHTTPStatusCodeSuccessUnknown = 2,
    JCHTTPStatusCodeOK = 200,
    JCHTTPStatusCodeCreated = 201,
    JCHTTPStatusCodeAccepted = 202,
    JCHTTPStatusCodeNonAuthoritativeInformation = 203,
    JCHTTPStatusCodeNoContent = 204,
    JCHTTPStatusCodeResetContent = 205,
    JCHTTPStatusCodePartialContent = 206,
    JCHTTPStatusCodeMultiStatus = 207,
    JCHTTPStatusCodeAlreadyReported = 208,
    JCHTTPStatusCodeIMUsed = 209,
    
    // Redirection
    JCHTTPStatusCodeRedirectionSuccessUnknown = 3,
    JCHTTPStatusCodeMultipleChoices = 300,
    JCHTTPStatusCodeMovedPermanently = 301,
    JCHTTPStatusCodeFound = 302,
    JCHTTPStatusCodeSeeOther = 303,
    JCHTTPStatusCodeNotModified = 304,
    JCHTTPStatusCodeUseProxy = 305,
    JCHTTPStatusCodeSwitchProxy = 306,
    JCHTTPStatusCodeTemporaryRedirect = 307,
    JCHTTPStatusCodePermanentRedirect = 308,
    
    // Client error
    JCHTTPStatusCode4XXSuccessUnknown = 4,
    JCHTTPStatusCodeBadRequest = 400,
    JCHTTPStatusCodeUnauthorised = 401,
    JCHTTPStatusCodePaymentRequired = 402,
    JCHTTPStatusCodeForbidden = 403,
    JCHTTPStatusCodeNotFound = 404,
    JCHTTPStatusCodeMethodNotAllowed = 405,
    JCHTTPStatusCodeNotAcceptable = 406,
    JCHTTPStatusCodeProxyAuthenticationRequired = 407,
    JCHTTPStatusCodeRequestTimeout = 408,
    JCHTTPStatusCodeConflict = 409,
    JCHTTPStatusCodeGone = 410,
    JCHTTPStatusCodeLengthRequired = 411,
    JCHTTPStatusCodePreconditionFailed = 412,
    JCHTTPStatusCodeRequestEntityTooLarge = 413,
    JCHTTPStatusCodeRequestURITooLong = 414,
    JCHTTPStatusCodeUnsupportedMediaType = 415,
    JCHTTPStatusCodeRequestedRangeNotSatisfiable = 416,
    JCHTTPStatusCodeExpectationFailed = 417,
    JCHTTPStatusCodeIamATeapot = 418,
    JCHTTPStatusCodeAuthenticationTimeout = 419,
    JCHTTPStatusCodeMethodFailureSpringFramework = 420,
    JCHTTPStatusCodeEnhanceYourCalmTwitter = 4200,
    JCHTTPStatusCodeUnprocessableEntity = 422,
    JCHTTPStatusCodeLocked = 423,
    JCHTTPStatusCodeFailedDependency = 424,
    JCHTTPStatusCodeMethodFailureWebDaw = 4240,
    JCHTTPStatusCodeUnorderedCollection = 425,
    JCHTTPStatusCodeUpgradeRequired = 426,
    JCHTTPStatusCodePreconditionRequired = 428,
    JCHTTPStatusCodeTooManyRequests = 429,
    JCHTTPStatusCodeRequestHeaderFieldsTooLarge = 431,
    JCHTTPStatusCodeNoResponseNginx = 444,
    JCHTTPStatusCodeRetryWithMicrosoft = 449,
    JCHTTPStatusCodeBlockedByWindowsParentalControls = 450,
    JCHTTPStatusCodeRedirectMicrosoft = 451,
    JCHTTPStatusCodeUnavailableForLegalReasons = 4510,
    JCHTTPStatusCodeRequestHeaderTooLargeNginx = 494,
    JCHTTPStatusCodeCertErrorNginx = 495,
    JCHTTPStatusCodeNoCertNginx = 496,
    JCHTTPStatusCodeHTTPToHTTPSNginx = 497,
    JCHTTPStatusCodeClientClosedRequestNginx = 499,
    
    // Server error
    JCHTTPStatusCode5XXSuccessUnknown = 5,
    JCHTTPStatusCodeInternalServerError = 500,
    JCHTTPStatusCodeNotImplemented = 501,
    JCHTTPStatusCodeBadGateway = 502,
    JCHTTPStatusCodeServiceUnavailable = 503,
    JCHTTPStatusCodeGatewayTimeout = 504,
    JCHTTPStatusCodeHTTPVersionNotSupported = 505,
    JCHTTPStatusCodeVariantAlsoNegotiates = 506,
    JCHTTPStatusCodeInsufficientStorage = 507,
    JCHTTPStatusCodeLoopDetected = 508,
    JCHTTPStatusCodeBandwidthLimitExceeded = 509,
    JCHTTPStatusCodeNotExtended = 510,
    JCHTTPStatusCodeNetworkAuthenticationRequired = 511,
    JCHTTPStatusCodeConnectionTimedOut = 522,
    JCHTTPStatusCodeNetworkReadTimeoutErrorUnknown = 598,
    JCHTTPStatusCodeNetworkConnectTimeoutErrorUnknown = 599
};

@interface JCApiClientError : JCError

@property (nonatomic, readonly) NSInteger underlyingStatusCode;

+(NSInteger)underlyingErrorCodeForError:(NSError *)error;

@end

