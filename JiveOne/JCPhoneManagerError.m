//
//  JCPhoneManagerError.m
//  JiveOne
//
//  Created by Robert Barclay on 1/15/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCPhoneManagerError.h"

NSString *const kJCPhoneManagerErrorDomain = @"PhoneManagerDomain";

@implementation JCPhoneManagerError

+(instancetype)errorWithCode:(NSInteger)code userInfo:(NSDictionary *)userInfo
{
    return [self errorWithDomain:kJCPhoneManagerErrorDomain code:code userInfo:userInfo];
}

+(instancetype)errorWithCode:(NSInteger)code reason:(NSString *)reason underlyingError:(NSError *)error
{
    return [self errorWithDomain:kJCPhoneManagerErrorDomain code:code reason:reason underlyingError:error];
}

+(NSString *)failureReasonFromCode:(NSInteger)code
{
    switch (code) {            
        case JS_PHONE_SIP_NOT_INITIALIZED:
            return @"Phone could not be initialized";
            
        case JS_PHONE_WIFI_DISABLED:
            return @"Phone is set to be Wifi Only";
            
        case JS_PHONE_ALREADY_CONNECTING:
            return @"Phone is already attempting to connect";
            
        case JS_PHONE_LINE_IS_NULL:
            return @"Line is null";
            
        case JC_PHONE_LINE_CONFIGURATION_REQUEST_ERROR:
            return @"Unable to connect to this line at this time. Please Try again.";
    }
    return nil;
}

@end
