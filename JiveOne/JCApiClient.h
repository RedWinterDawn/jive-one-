//
//  JCClient.h
//  JiveOne
//
//  Created by Robert Barclay on 1/5/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

@import Foundation;

#import <AFNetworking/AFNetworking.h>

@interface JCApiClient : NSObject
{
    AFHTTPRequestOperationManager *_manager;
}

@property (nonatomic, strong) AFHTTPRequestOperationManager *manager;

-(instancetype)initWithBaseURL:(NSURL *)url;

+ (void)cancelAllOperations;

@end

#pragma mark Error Handling

typedef enum : NSUInteger {
    JCApiClientUnknownErrorCode = 0,
    JCApiClientInvalidArgumentErrorCode,
    JCApiClientInvalidRequestParameterErrorCode,
    JCApiClientRequestErrorCode,
    JCApiClientResponseErrorCode,
    JCApiClientResponseParserErrorCode,
    JCApiClientUnexpectedResponseErrorCode,
    JCApiClientCoreDataErrorCode
} JCApiClientErrorCode;

@interface JCApiClientError : NSError

+(instancetype)errorWithCode:(JCApiClientErrorCode)code reason:(NSString *)reason;
+(instancetype)errorWithCode:(JCApiClientErrorCode)code userInfo:(NSDictionary *)userInfo;

@end

#pragma mark Serialization

@interface JCAuthenticationJSONRequestSerializer : AFJSONRequestSerializer

@end

@interface JCAuthenticationXmlRequestSerializer : AFHTTPRequestSerializer

@end


@interface JCXMLParserResponseSerializer : AFHTTPResponseSerializer

@end

