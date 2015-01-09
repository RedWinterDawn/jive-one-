//
//  JCClient.m
//  JiveOne
//
//  Created by Robert Barclay on 1/5/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCApiClient.h"

#import "JCAuthenticationManager.h"
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

@end

@implementation JCApiClientError

+(instancetype)errorWithCode:(JCApiClientErrorCode)code reason:(NSString *)reason
{
    return [self errorWithDomain:kJCApiClientErrorDomain code:code userInfo:@{NSLocalizedDescriptionKey: reason}];
}

+(instancetype)errorWithCode:(JCApiClientErrorCode)code userInfo:(NSDictionary *)userInfo
{
    return [self errorWithDomain:kJCApiClientErrorDomain code:code userInfo:userInfo];
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
    NSString *authToken = [JCAuthenticationManager sharedInstance].authToken;
    [mutableRequest setValue:authToken forHTTPHeaderField:kJCApiClientAuthorizationHeaderFieldKey];
    return mutableRequest;
}

@end

@implementation JCBearerAuthenticationJSONRequestSerializer

- (NSURLRequest *)requestBySerializingRequest:(NSURLRequest *)request withParameters:(id)object error:(NSError *__autoreleasing *)error
{
    NSMutableURLRequest *mutableRequest = [[super requestBySerializingRequest:request withParameters:object error:error] mutableCopy];
    NSString *authToken = [JCAuthenticationManager sharedInstance].authToken;
    [mutableRequest setValue:[NSString stringWithFormat:@"Bearer %@", authToken] forHTTPHeaderField:kJCApiClientAuthorizationHeaderFieldKey];
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
        *error = [JCApiClientError errorWithCode:JCApiClientInvalidArgumentErrorCode reason:@"object is not the class type NSData"];
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
    NSString *authToken = [JCAuthenticationManager sharedInstance].authToken;
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
        *error = [JCApiClientError errorWithCode:JCApiClientResponseParserErrorCode reason:@"Response Empty"];
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