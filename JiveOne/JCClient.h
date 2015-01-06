//
//  JCClient.h
//  JiveOne
//
//  Created by Robert Barclay on 1/5/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

@import Foundation;

#import <AFNetworking/AFNetworking.h>

@interface JCClient : NSObject
{
    AFHTTPRequestOperationManager *_manager;
}

@property (nonatomic, strong) AFHTTPRequestOperationManager *manager;

-(instancetype)initWithBaseURL:(NSURL *)url;

@end

#pragma mark Error Handling

typedef enum : NSUInteger {
    JCClientUnknownErrorCode = 0,
    JCClientInvalidArgumentErrorCode,
    JCClientInvalidRequestParameterErrorCode,
    JCClientRequestErrorCode,
    JCClientResponseParserErrorCode,
    JCClientUnexpectedResponseErrorCode,
    JCClientCoreDataErrorCode
} JCClientErrorCode;

@interface JCClientError : NSError

+(instancetype)errorWithCode:(JCClientErrorCode)code reason:(NSString *)reason;
+(instancetype)errorWithCode:(JCClientErrorCode)code userInfo:(NSDictionary *)userInfo;

@end

#pragma mark Serialization

@interface JCAuthenticationJSONRequestSerializer : AFJSONRequestSerializer

@end

@interface JCAuthenticationXmlRequestSerializer : AFHTTPRequestSerializer

@end


@interface JCXMLParserResponseSerializer : AFHTTPResponseSerializer

@end

