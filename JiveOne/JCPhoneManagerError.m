//
//  JCPhoneManagerError.m
//  JiveOne
//
//  Created by Robert Barclay on 8/7/15.
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
        case JC_PHONE_SIP_NOT_INITIALIZED:
            return NSLocalizedStringFromTable(@"Phone could not be initialized", JC_PHONE_STRINGS_NAME, @"Phone Manager Error");
            
            // Registration
        case JC_PHONE_WIFI_DISABLED:
            return NSLocalizedStringFromTable(@"Phone is set to be Wifi Only", JC_PHONE_STRINGS_NAME, @"Phone Manager Error");
            
        case JC_PHONE_MANAGER_NO_NETWORK:
            return NSLocalizedStringFromTable(@"Unable to connect to the\n network at this time.", JC_PHONE_STRINGS_NAME, @"Phone Manager Error");
            
        case JC_PHONE_LINE_CONFIGURATION_REQUEST_ERROR:
            return NSLocalizedStringFromTable(@"Unable to connect to this line at this time. Please Try again.", JC_PHONE_STRINGS_NAME, @"Phone Manager Error");
            
            // Conference Calls
        case JC_PHONE_CONFERENCE_CALL_ALREADY_EXISTS:
            return NSLocalizedStringFromTable(@"Conference Call already exists", JC_PHONE_STRINGS_NAME, @"Phone Manager Error");
            
        case JC_PHONE_FAILED_TO_CREATE_CONFERENCE_CALL:
            return NSLocalizedStringFromTable(@"Failed to create conference call", JC_PHONE_STRINGS_NAME, @"Phone Manager Error");
            
        case JC_PHONE_NO_CONFERENCE_CALL_TO_END:
            return NSLocalizedStringFromTable(@"No Conference call to end", JC_PHONE_STRINGS_NAME, @"Phone Manager Error");
            
        case JC_PHONE_FAILED_ENDING_CONFERENCE_CALL:
            return NSLocalizedStringFromTable(@"Failed ending conference call", JC_PHONE_STRINGS_NAME, @"Phone Manager Error");
            
        default:
            return NSLocalizedStringFromTable(@"An unknown error has occured. If this problem persists, please contact support.", JC_PHONE_STRINGS_NAME, @"Phone Manager Error");
            
    }
    return nil;
}

@end
