//
//  JCAuthenticationManagerError.m
//  JiveOne
//
//  Created by Robert Barclay on 11/21/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCAuthenticationManagerError.h"

NSString *const kJCAuthenticationManagerError = @"AuthenticationManagerError";

@implementation JCAuthenticationManagerError

+(instancetype)errorWithType:(JCAuthenticationManagerErrorType)type description:(NSString *)description
{
    NSString *reason = [JCAuthenticationManagerError stringForType:type];
    NSDictionary *userInfo = @{
                               NSLocalizedFailureReasonErrorKey:NSLocalizedString(reason, nil),
                               NSLocalizedDescriptionKey:NSLocalizedString(description, nil)
                               };
    
    return [JCAuthenticationManagerError errorWithDomain:kJCAuthenticationManagerError
                                                    code:type
                                                userInfo:userInfo];
}

+(NSString *)stringForType:(JCAuthenticationManagerErrorType)type
{
    switch (type) {
        case InvalidAuthenticationParameters:
            return @"Invalid Parameters";
            
        case AutheticationError:
            return @"Authentication Error";
            
        case NoPbx:
            return @"No PBX";
            
        case MultiplePbx:
            return @"Multiple PBXs";
            
        case NetworkError:
            return @"Server Unavailable";
            
        default:
            return @"";
    }
}

@end
