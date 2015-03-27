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



#pragma mark Serialization

@interface JCAuthenticationJSONRequestSerializer : AFJSONRequestSerializer

@end

@interface JCBearerAuthenticationJSONRequestSerializer : JCAuthenticationJSONRequestSerializer

@end

@interface JCXmlRequestSerializer : AFHTTPRequestSerializer

@end

@interface JCAuthenticationXmlRequestSerializer : JCXmlRequestSerializer

@end

@interface JCXMLParserResponseSerializer : AFHTTPResponseSerializer

@end

#import "JCError.h"

#pragma mark Error Handling

#define API_CLIENT_UNKNOWN_ERROR                1000
#define API_CLIENT_INVALID_ARGUMENTS            1001
#define API_CLIENT_INVALID_REQUEST_PARAMETERS   1002
#define API_CLIENT_REQUEST_ERROR                1003
#define API_CLIENT_RESPONSE_ERROR               1004
#define API_CLIENT_RESPONSE_PARSER_ERROR        1005
#define API_CLIENT_UNEXPECTED_RESPONSE_ERROR    1006
#define API_CLIENT_CORE_DATE_ERROR              1007

#define API_CLIENT_AUTHENTICATION_ERROR         1008
#define API_CLIENT_NETWORK_ERROR                1009
#define API_CLIENT_TIMEOUT_ERROR                1010
#define API_CLIENT_NO_PBX_ERROR                 1011

@interface JCApiClientError : JCError

@end

