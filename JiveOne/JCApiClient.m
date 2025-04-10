//
//  JCClient.m
//  JiveOne
//
//  Created by Robert Barclay on 1/5/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCApiClient.h"

#import "JCUserManager.h"
#import <XMLDictionary/XMLDictionary.h>

NSMutableArray *operationQueues;

NSString *const kJCApiClientAuthorizationHeaderFieldKey = @"Authorization";
NSString *const kJCApiClientErrorDomain = @"JCClientError";

@implementation JCApiClient

-(instancetype)initWithBaseURL:(NSURL *)url
{
    self = [super init];
    {
        _manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:url];

        #if DEBUG
        _manager.securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
        _manager.securityPolicy.allowInvalidCertificates = YES;
        #endif
        
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            operationQueues = [[NSMutableArray alloc] init];
        });
        
        NSOperationQueue *queue = _manager.operationQueue;
        if (![operationQueues containsObject:queue]) {
            [operationQueues addObject:queue];
        }
    }
    return self;
}

-(void)dealloc
{
    NSOperationQueue *queue = _manager.operationQueue;
    if ([operationQueues containsObject:queue]) {
        [operationQueues removeObject:queue];
    }
}

+(void)cancelAllOperations
{
    for (NSOperationQueue *operationQueue in operationQueues) {
        [operationQueue cancelAllOperations];
    }
}

+(void)getWithPath:(NSString *)path
        parameters:(NSDictionary *)parameters
 requestSerializer:(AFHTTPRequestSerializer *)requestSerializer
           retries:(NSUInteger)retries
        completion:(JCApiClientCompletionHandler)completion
{
    [self requestWithType:JCApiClientGet
                     path:path parameters:parameters
        requestSerializer:requestSerializer
       responceSerializer:nil
                  retries:retries
                  success:^(id responseObject) {
                      if (completion) {
                          completion(YES, responseObject, nil);
                      };
                  }
                  failure:^(id responseObject, NSError *error) {
                      if (completion) {
                          completion(NO, responseObject, error);
                      }
                  }];
}

+(void)putWithPath:(NSString *)path
        parameters:(NSDictionary *)parameters
 requestSerializer:(AFHTTPRequestSerializer *)requestSerializer
           retries:(NSUInteger)retries
        completion:(JCApiClientCompletionHandler)completion
{
    [self requestWithType:JCApiClientPut
                     path:path parameters:parameters
        requestSerializer:requestSerializer
       responceSerializer:nil
                  retries:retries
                  success:^(id responseObject) {
                      if (completion) {
                          completion(YES, responseObject, nil);
                      };
                  }
                  failure:^(id responseObject, NSError *error) {
                      if (completion) {
                          completion(NO, responseObject, error);
                      }
                  }];
}

+(void)postWithPath:(NSString *)path
         parameters:(NSDictionary *)parameters
  requestSerializer:(AFHTTPRequestSerializer *)requestSerializer
            retries:(NSUInteger)retries
         completion:(JCApiClientCompletionHandler)completion
{
    [self requestWithType:JCApiClientPost
                     path:path
               parameters:parameters
        requestSerializer:requestSerializer
       responceSerializer:nil
                  retries:retries
                  success:^(id responseObject) {
                      if (completion) {
                          completion(YES, responseObject, nil);
                      };
                  }
                  failure:^(id responseObject, NSError *error) {
                      if (completion) {
                          completion(NO, responseObject, error);
                      }
                  }];
}

+(void)deleteWithPath:(NSString *)path
           parameters:(NSDictionary *)parameters
    requestSerializer:(AFHTTPRequestSerializer *)requestSerializer
              retries:(NSUInteger)retries
           completion:(JCApiClientCompletionHandler)completion
{
    [self requestWithType:JCApiClientDelete
                     path:path parameters:parameters
        requestSerializer:requestSerializer
       responceSerializer:nil
                  retries:retries
                  success:^(id responseObject) {
                      if (completion) {
                          completion(YES, responseObject, nil);
                      };
                  }
                  failure:^(id responseObject, NSError *error) {
                      if (completion) {
                          completion(NO, responseObject, error);
                      }
                  }];
}

#pragma mark - Private -

-(void)requestWithType:(JCApiClientCrudOperationType)type
                  path:(NSString *)path
            parameters:(NSDictionary *)parameters
     requestSerializer:(AFHTTPRequestSerializer *)requestSerializer
    responceSerializer:(AFHTTPResponseSerializer *)responceSerializer
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
        AFHTTPRequestOperationManager *manager = self.manager;
        if (requestSerializer) {
            manager.requestSerializer = requestSerializer;
        }
        
        if (responceSerializer) {
            manager.responseSerializer = responceSerializer;
        }
        
        void (^failureBlock)(AFHTTPRequestOperation *operation, NSError *error) = ^(AFHTTPRequestOperation *operation, NSError *error) {
            if (error.code == NSURLErrorTimedOut) {
                NSLog(@"Retry %lu for post to path %@", (long)retryCount, path);
                [self requestWithType:type
                                 path:path
                           parameters:parameters
                    requestSerializer:requestSerializer
                   responceSerializer:responceSerializer
                              retries:(retryCount - 1)
                              success:success
                              failure:failure];
            }
            else if (operation.response.statusCode == JCHTTPStatusCodeUnauthorised)
            {
                [JCUserManager requestAuthentication:^(BOOL authenticated, NSError *error) {
                    if (authenticated) {
                        [self requestWithType:type
                                         path:path
                                   parameters:parameters
                            requestSerializer:requestSerializer
                           responceSerializer:responceSerializer
                                      retries:(retryCount - 1)
                                      success:success
                                      failure:failure];
                    } else {
                        failure(operation.responseObject, [JCApiClientError errorWithCode:API_CLIENT_REQUEST_ERROR underlyingError:error]);
                    }
                }];
            }
            else{
                failure(operation.responseObject, [JCApiClientError errorWithCode:API_CLIENT_REQUEST_ERROR underlyingError:error]);
            }
        };
        
        void (^sucessBlock)(AFHTTPRequestOperation *operation, id responseObject) = ^(AFHTTPRequestOperation *operation, id responseObject) {
            success(responseObject);
        };
        
        switch (type) {
            case JCApiClientPost:
                [manager POST:path parameters:parameters success:sucessBlock failure:failureBlock];
                break;
                
            case JCApiClientPut:
                [manager PUT:path parameters:parameters success:sucessBlock failure:failureBlock];
                break;
                
            case JCApiClientDelete:
                [manager DELETE:path parameters:parameters success:sucessBlock failure:failureBlock];
                break;
                
            default:
                [manager GET:path parameters:parameters success:sucessBlock failure:failureBlock];
                break;
        }
    }
}


+(void)requestWithType:(JCApiClientCrudOperationType)type
                  path:(NSString *)path
            parameters:(NSDictionary *)parameters
     requestSerializer:(AFHTTPRequestSerializer *)requestSerializer
    responceSerializer:(AFHTTPResponseSerializer *)responceSerializer
               retries:(NSUInteger)retryCount
               success:(void (^)(id responseObject))success
               failure:(void (^)(id responseObject, NSError *error))failure
{
    
    JCApiClient *client = [self new];
    [client requestWithType:type
                       path:path
                 parameters:parameters
          requestSerializer:requestSerializer
         responceSerializer:responceSerializer
                    retries:retryCount
                    success:success
                    failure:failure];
}

@end



@implementation JCAuthenticationJSONRequestSerializer

+(instancetype)serializer
{
    JCAuthenticationJSONRequestSerializer *serializer = [self new];
    [serializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    serializer.cachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
    serializer.HTTPShouldHandleCookies = FALSE;
    return serializer;
}

- (NSURLRequest *)requestBySerializingRequest:(NSURLRequest *)request withParameters:(id)object error:(NSError *__autoreleasing *)error
{
    NSMutableURLRequest *mutableRequest = [[super requestBySerializingRequest:request withParameters:object error:error] mutableCopy];
    NSString *authToken = [UIApplication sharedApplication].userManager.authToken.accessToken;
    if (authToken) {
        [mutableRequest setValue:authToken forHTTPHeaderField:kJCApiClientAuthorizationHeaderFieldKey];
    }
    return mutableRequest;
}

@end

@implementation JCBearerAuthenticationJSONRequestSerializer

- (NSURLRequest *)requestBySerializingRequest:(NSURLRequest *)request withParameters:(id)object error:(NSError *__autoreleasing *)error
{
    NSMutableURLRequest *mutableRequest = [[super requestBySerializingRequest:request withParameters:object error:error] mutableCopy];
    NSString *authToken = [UIApplication sharedApplication].userManager.authToken.accessToken;
    if (authToken) {
        [mutableRequest setValue:[NSString stringWithFormat:@"bearer %@", authToken] forHTTPHeaderField:kJCApiClientAuthorizationHeaderFieldKey];
    }
    return mutableRequest;
}

@end

@implementation JCXmlRequestSerializer : AFHTTPRequestSerializer

+(instancetype)serializer
{
    JCAuthenticationXmlRequestSerializer *serializer = [self new];
    serializer.cachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
    serializer.HTTPShouldHandleCookies = FALSE;
    [serializer setValue:@"application/xml" forHTTPHeaderField:@"Content-Type"];
    return serializer;
}

- (NSURLRequest *)requestBySerializingRequest:(NSURLRequest *)request withParameters:(id)object error:(NSError *__autoreleasing *)error
{
    if (![object isKindOfClass:[NSData class]]) {
        if (error != NULL) {
            *error = [JCApiClientError errorWithCode:API_CLIENT_INVALID_ARGUMENTS reason:@"Object is not the class type NSData"];
        }
        return nil;
    }
    
    NSData *data = object;
    NSMutableURLRequest *mutableRequest = [request mutableCopy];
    [mutableRequest setValue:[NSString stringWithFormat:@"%lu", (unsigned long)data.length] forHTTPHeaderField:@"Content-Length"];
    [mutableRequest setHTTPBody:data];
    return mutableRequest;
}

@end

@implementation JCAuthenticationXmlRequestSerializer

- (NSURLRequest *)requestBySerializingRequest:(NSURLRequest *)request withParameters:(id)object error:(NSError *__autoreleasing *)error
{
    NSMutableURLRequest *mutableRequest = [[super requestBySerializingRequest:request withParameters:object error:error] mutableCopy];
    NSString *authToken = [UIApplication sharedApplication].userManager.authToken.accessToken;
    [mutableRequest setValue:authToken forHTTPHeaderField:kJCApiClientAuthorizationHeaderFieldKey];
    return mutableRequest;
}

@end

@implementation JCXMLParserResponseSerializer

+ (instancetype)serializer {
    JCXMLParserResponseSerializer *serializer = [self new];
    return serializer;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.acceptableContentTypes = [[NSSet alloc] initWithObjects:@"application/xml", @"text/xml", @"text/html;charset=ISO-8859-1", @"text/html", nil];
    }
    return self;
}

#pragma mark - AFURLResponseSerialization

- (id)responseObjectForResponse:(NSHTTPURLResponse *)response data:(NSData *)data error:(NSError *__autoreleasing *)error
{
    if (![self validateResponse:(NSHTTPURLResponse *)response data:data error:error]) {
        if (JCErrorOrUnderlyingErrorHasCode(*error, NSURLErrorCannotDecodeContentData)) {
            return nil;
        }
    }
    
    // Process Response Data
    NSDictionary *responseObject = [NSDictionary dictionaryWithXMLData:data];
    if (!response) {
        if (error != NULL) {
            *error = [JCApiClientError errorWithCode:API_CLIENT_RESPONSE_PARSER_ERROR reason:@"Response Empty"];
        }
    }
    
    return responseObject;
}


static BOOL JCErrorOrUnderlyingErrorHasCode(NSError *error, NSInteger code) {
    if (error.code == code) {
        return YES;
    } else if (error.userInfo[NSUnderlyingErrorKey]) {
        return JCErrorOrUnderlyingErrorHasCode(error.userInfo[NSUnderlyingErrorKey], code);
    }
    return NO;
}

@end

@implementation JCApiClientError

+(instancetype)errorWithCode:(NSInteger)code userInfo:(NSDictionary *)userInfo
{
    return [self errorWithDomain:[self domain] code:code userInfo:userInfo];
}

+(instancetype)errorWithCode:(NSInteger)code reason:(NSString *)reason underlyingError:(NSError *)error
{
    return [self errorWithDomain:[self domain] code:code reason:reason underlyingError:error];
}

+(NSString *)domain
{
    return [NSString stringWithFormat:@"%@Domain", NSStringFromClass([self class])];
}

+(NSString *)failureReasonFromCode:(NSInteger)code
{
    switch (code) {
        case API_CLIENT_INVALID_ARGUMENTS:
            return @"Invalid Arguments";
            
        case API_CLIENT_INVALID_REQUEST_PARAMETERS:
            return @"Invalid Arguments";
            
        case API_CLIENT_RESPONSE_PARSER_ERROR:
            return @"Response Empty";
            
        case API_CLIENT_NETWORK_ERROR:
            return @"Network error please check your connection.";
            
        case API_CLIENT_TIMEOUT_ERROR:
            return @"It took to long to get an answer try again.";
            
//        case API_CLIENT_RESPONSE_ERROR:
//            return @"Server returned an invalid server response.";
            
        case API_CLIENT_AUTHENTICATION_ERROR:
            return @"Authentication was invalid please check Username and Password";
            
        case API_CLIENT_NO_PBX_ERROR:
            return @" No Pbx was found.";
            
        case API_CLIENT_SMS_RESPONSE_INVALID:
            return @"Server returned an invalid server response.";
            
        case API_CLIENT_SMS_FAILED_CODE_OAUTH:
            return @"OAuth validation failed.";
            
        case API_CLIENT_SMS_FAILED_CODE_NO_DID:
            return @"No matching DIDs for 'from' number where found.";
            
        case API_CLIENT_SMS_FAILED_CODE_PBX_DISABLED:
            return @"SMS PBX flag is disabled.";
            
        case API_CLIENT_SMS_FAILED_CODE_PEER_DISABLED:
            return @" SMS Peer flag is disabled.";
            
        case API_CLIENT_SMS_MESSAGE_CAP_REACHED:
            return @"Hourly, daily or montly cap has been reached.";
            
        case API_CLIENT_SMS_MESSAGE_CAP_UNDEFINED:
            return @"Hourly, daily and montly caps have not been defined.";
            
//        default:
//            return @"Unknown Error Has Occured.";
    }
    return nil;
}

-(NSInteger)underlyingStatusCode
{
    return [[self class] underlyingErrorCodeForError:self];
}

+(NSInteger)underlyingErrorCodeForError:(NSError *)error
{
    error = [self underlyingErrorForError:error];
    if ([error.domain isEqualToString:AFURLResponseSerializationErrorDomain]) {
        NSHTTPURLResponse *urlResponse = [error.userInfo valueForKey:AFNetworkingOperationFailingURLResponseErrorKey];
        return urlResponse.statusCode;
    }
    return error.code;
}

@end