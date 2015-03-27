//
//  JCSMSError.m
//  JiveOne
//
//  Created by P Leonard on 2/16/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCSMSClientError.h"

NSString *const kJCSMSErrorDomain = @"SMSErrorDomain";

@implementation JCSMSClientError

+(instancetype)errorWithCode:(NSInteger)code userInfo:(NSDictionary *)userInfo
{
    return [self errorWithDomain:kJCSMSErrorDomain code:code userInfo:userInfo];
}

+(instancetype)errorWithCode:(NSInteger)code reason:(NSString *)reason underlyingError:(NSError *)error
{
    return [self errorWithDomain:kJCSMSErrorDomain code:code reason:reason underlyingError:error];
}

+(NSString *)failureReasonFromCode:(NSInteger)code
{
    switch (code) {
        case SMS_RESPONSE_INVALID:
            return @"Server returned an invalid server response.";
        
        case SMS_FAILED_CODE_OAUTH:
            return @"OAuth validation failed.";
            
        case SMS_FAILED_CODE_NO_DID:
            return @"No matching DIDs for 'from' number where found.";
            
        case SMS_FAILED_CODE_PBX_DISABLED:
            return @"SMS PBX flag is disabled.";
            
        case SMS_FAILED_CODE_PEER_DISABLED:
            return @" SMS Peer flag is disabled.";
            
        case SMS_MESSAGE_CAP_REACHED:
            return @"Hourly, daily or montly cap has been reached.";
            
        case SMS_MESSAGE_CAP_UNDEFINED:
            return @"Hourly, daily and montly caps have not been defined.";
        
        default:
            return @"Unknown Error Has Occured.";
    }
    return nil;
}

@end
