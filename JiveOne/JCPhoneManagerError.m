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
        
        // Initialization
        case JS_PHONE_SIP_NOT_INITIALIZED:
            return @"Phone could not be initialized";
         
        // Registration
        case JS_PHONE_WIFI_DISABLED:
            return @"Phone is set to be Wifi Only";
        
        case JC_PHONE_MANAGER_NO_NETWORK:
            return @"No Network Connection. Please Check your network connection and try again.";
            
        case JS_PHONE_ALREADY_CONNECTING:
            return @"Phone is already attempting to connect";
            
        case JS_PHONE_LINE_IS_NULL:
            return @"Line is empty";
            
        case JC_PHONE_LINE_CONFIGURATION_REQUEST_ERROR:
            return @"Unable to connect to this line at this time. Please Try again.";
            
        case JC_REG_TIMEOUT :
            return @"Can't register, check network connection, If problem persists please restart the app.";
            
            
         // Conference Calls
        case JC_PHONE_CONFERENCE_CALL_ALREADY_EXISTS:
            return @"Conference Call already exists";
            
        case JC_PHONE_FAILED_TO_CREATE_CONFERENCE_CALL:
            return @"Failed to create conference call";
            
        case JC_PHONE_NO_CONFERENCE_CALL_TO_END:
            return @"No Conference call to end";
            
        case JC_PHONE_FAILED_ENDING_CONFERENCE_CALL:
            return @"Failed ending conference call";
            
    }
    return nil;
}

@end
