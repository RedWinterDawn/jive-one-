//
//  JCSMSClient.m
//  JiveOne
//
//  Created by P Leonard on 2/16/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCSMSClient.h"


#ifndef DEBUG
NSString *const kJCSMSClientBaseUrl = @"https://api.jive.com/sms";
#else
NSString *const kJCSMSClientBaseUrl = @"http://10.20.130.20:60257";
#endif


@implementation JCSMSClient

-(instancetype)init
{
    return [self initWithBaseURL:[NSURL URLWithString:kJCSMSClientBaseUrl]];
}

-(instancetype)initWithBaseURL:(NSURL *)url
{
    self = [super initWithBaseURL:url];
    if (self) {
        _manager.responseSerializer = [AFJSONResponseSerializer serializer];
        _manager.requestSerializer = [JCAuthenticationJSONRequestSerializer serializer];
    }
    return self;
}












//To send an SMS, POST to the following endpoint passing a simple JSON object (remember the token has to have been created with the 'sms.v1.send' scope):
//
//External Clients:
//Authorization: Bearer {token}
//POST https://api.jive.com/sms-temp/sendSmsExternal
//
//Internal Services:
//POST https://api.jive.com/sms-temp/sendSms
//
//Payload:
//
//{
//    "to":"{recipient}",
//    "from":"{did_number}",
//    "body":"{message}"
//}
//which returns (application/json):
//
//{
//    "status":"{status}",
//    "errorMessage":"{errorMessage}",
//    "errorCode":{errorCode}
//}
//Error messages that are generated by the service are obfuscated. A general "Cannot send SMS" message will be created along side with the follwing codes:
//
//SMS_FAILED_CODE_OAUTH           = 1001; - OAuth validation failed
//SMS_FAILED_CODE_USER_PERMISSION = 1002; - User does not have permission to send SMS on DID
//SMS_FAILED_CODE_NO_DID          = 1003; - No mathing DIDs for 'from' number where found
//SMS_FAILED_CODE_PBX_DISABLED    = 1004; - SMS PBX flag is disabled
//SMS_FAILED_CODE_PEER_DISABLED   = 1005; - SMS Peer flag is disabled
//SMS_MESSAGE_CAP_REACHED         = 2001; - Hourly, daily or montly cap has been reached
//SMS_MESSAGE_CAP_UNDEFINED       = 2002; - Hourly, daily and montly caps have not been defined
//Error messages that are generated by the Peer (eg. Level3, Bandwidth) will have it's own messages and codes.
@end
