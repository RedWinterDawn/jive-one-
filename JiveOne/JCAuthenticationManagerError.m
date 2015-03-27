//
//  JCAuthenticationManagerError.m
//  JiveOne
//
//  Created by Robert Barclay on 11/21/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCAuthenticationManagerError.h"

NSString *const kJCAuthManagerError = @"AuthenticationManagerError";

@implementation JCAuthenticationManagerError

+(instancetype)errorWithCode:(NSInteger)code userInfo:(NSDictionary *)userInfo
{
    return [self errorWithDomain:kJCAuthManagerError code:code userInfo:userInfo];
}

+(instancetype)errorWithCode:(NSInteger)code reason:(NSString *)reason underlyingError:(NSError *)error
{
    return [self errorWithDomain:kJCAuthManagerError code:code reason:reason underlyingError:error];
}

+(instancetype)errorWithCode:(NSInteger)code reason:(NSString *)reason
{
    return [self errorWithDomain:kJCAuthManagerError code:code reason:reason];
}

+(NSString *)failureReasonFromCode:(NSInteger)code
{
    switch (code) {
        case AUTH_MANAGER_CLIENT_ERROR:
            return @"We are unable to login at this time, Please Check Your Connection and try again.";
            
        case AUTH_MANAGER_PBX_INFO_ERROR:
            return @"We could not reach the server at this time to sync data. Please check your connection, and try again.";
         
        case AUTH_MANAGER_AUTH_TOKEN_ERROR:
            return @"There was an error logging in. Please Contact Support.";
            
        default:
            return @"Unknown Error Has Occured.";
    }
    return nil;
}

@end
