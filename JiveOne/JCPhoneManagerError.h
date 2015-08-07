//
//  JCPhoneManagerError.h
//  JiveOne
//
//  Created by Robert Barclay on 8/7/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCError.h"

#define JC_PHONE_STRINGS_NAME @"Phone"

#define JC_PHONE_SIP_NOT_INITIALIZED                -1000
#define JC_PHONE_WIFI_DISABLED                      -1001
#define JC_PHONE_MANAGER_NO_NETWORK                 -1002
#define JC_PHONE_LINE_CONFIGURATION_REQUEST_ERROR   -1003

#define JC_PHONE_CONFERENCE_CALL_ALREADY_EXISTS     -1100
#define JC_PHONE_FAILED_TO_CREATE_CONFERENCE_CALL   -1101
#define JC_PHONE_NO_CONFERENCE_CALL_TO_END          -1102
#define JC_PHONE_FAILED_ENDING_CONFERENCE_CALL      -1103
#define JC_PHONE_BLIND_TRANSFER_FAILED              -1104
#define JC_PHONE_SIP_DISABLED                       -1105

@interface JCPhoneManagerError : JCError

@end