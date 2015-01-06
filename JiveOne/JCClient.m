//
//  JCClient.m
//  JiveOne
//
//  Created by Robert Barclay on 1/5/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCClient.h"

#import "JCAuthenticationManager.h"
#import <XMLDictionary/XMLDictionary.h>

NSString *const kJCClientAuthorizationHeaderFieldKey = @"Authorization";

@implementation JCClient

-(instancetype)initWithBaseURL:(NSURL *)url
{
    self = [super init];
    {
        _manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:url];

        #if DEBUG
        _manager.securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
        _manager.securityPolicy.allowInvalidCertificates = YES;
        #endif
    }
    return self;
}

@end

NSString *const JCClientErrorDomain = @"JCClientError";

@implementation JCClientError

+(instancetype)errorWithCode:(JCClientErrorCode)code reason:(NSString *)reason
{
    return [self errorWithDomain:JCClientErrorDomain code:code userInfo:@{NSLocalizedDescriptionKey: reason}];
}

+(instancetype)errorWithCode:(JCClientErrorCode)code userInfo:(NSDictionary *)userInfo
{
    return [self errorWithDomain:JCClientErrorDomain code:code userInfo:userInfo];
}

@end

@implementation JCAuthenticationJSONRequestSerializer

+(instancetype)serializer
{
    JCAuthenticationJSONRequestSerializer *serializer = [self new];
    NSString *authToken = [JCAuthenticationManager sharedInstance].authToken;
    [serializer setValue:authToken forHTTPHeaderField:kJCClientAuthorizationHeaderFieldKey];
    return serializer;
}

+ (instancetype)serializerWithWritingOptions:(NSJSONWritingOptions)writingOptions
{
    JCAuthenticationJSONRequestSerializer *serializer = [JCAuthenticationJSONRequestSerializer serializer];
    serializer.writingOptions = writingOptions;
    return serializer;
}

@end

@implementation JCAuthenticationXmlRequestSerializer

+(instancetype)serializer
{
    JCAuthenticationXmlRequestSerializer *serializer = [self new];
    NSString *authToken = [JCAuthenticationManager sharedInstance].authToken;
    [serializer setValue:authToken forHTTPHeaderField:kJCClientAuthorizationHeaderFieldKey];
    return serializer;
}

- (NSURLRequest *)requestBySerializingRequest:(NSURLRequest *)request withParameters:(id)parameters error:(NSError *__autoreleasing *)error
{
    
    return request;
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
        self.acceptableContentTypes = [[NSSet alloc] initWithObjects:@"application/xml", @"text/xml", nil];
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
        *error = [JCClientError errorWithCode:JCClientResponseParserErrorCode reason:@"Response Empty"];
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