//
//  JCAuthenticationClientErrors.m
//  JiveOne
//
//  Created by P Leonard on 3/24/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCAuthClientError.h"

NSString *const kJCAuthErrorDomain = @"AuthErrorDomain";

@implementation JCAuthClientError

+(instancetype)errorWithCode:(NSInteger)code userInfo:(NSDictionary *)userInfo
{
    return [self errorWithDomain:kJCAuthErrorDomain code:code userInfo:userInfo];
}

+(instancetype)errorWithCode:(NSInteger)code reason:(NSString *)reason underlyingError:(NSError *)error
{
    return [self errorWithDomain:kJCAuthErrorDomain code:code reason:reason underlyingError:error];
}

+(NSString *)failureReasonFromCode:(NSInteger)code
{
    switch (code) {
        case AUTH_CLIENT_INVALID_PARAM:
            return @"Server returned an invalid server response.";
            
        case AUTH_CLIENT_AUTHENTICATION_ERROR:
            return @"Authentication was invalid please check Username and Password";
            
        case AUTH_CLIENT_NETWORK_ERROR:
            return @"Network error please check your connection.";
            
        case AUTH_CLIENT_TIMEOUT_ERROR:
            return @"It took to long to get an answer try again.";
            
        case AUTH_CLIENT_NO_PBX_ERROR:
            return @" No Pbx was found.";
            
        default:
            return @"Unknown Error Has Occured.";
    }
    return nil;
}

@end