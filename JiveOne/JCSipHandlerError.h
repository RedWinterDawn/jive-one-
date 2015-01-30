//
//  JCSipHandlerError.h
//  JiveOne
//
//  Created by Robert Barclay on 1/14/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCError.h"
#import <PortSIPLib/PortSIPSDK.h>

#define JC_SIP_REGISTER_LINE_IS_EMPTY                   -5000
#define JC_SIP_REGISTER_LINE_CONFIGURATION_IS_EMPTY     -5001
#define JC_SIP_REGISTER_LINE_PBX_IS_EMPTY               -5002
#define JC_SIP_REGISTER_USER_IS_EMPTY                   -5003
#define JC_SIP_REGISTER_SERVER_IS_EMPTY                 -5004
#define JC_SIP_REGISTER_PASSWORD_IS_EMPTY               -5005
#define JC_SIP_REGISTER_CALLER_ID_IS_EMPTY              -5006

#define JC_SIP_CALL_NO_IDLE_LINE                        -5100
#define JC_SIP_CALL_NO_ACTIVE_LINE                      -5101
#define JC_SIP_LINE_SESSION_IS_EMPTY                    -5102
#define JC_SIP_CALL_NO_REFERRAL_LINE                    -5103
#define JC_SIP_CALL_POOR_NETWORK_QUALITY                -5104

#define JC_SIP_CONFERENCE_CALL_ALREADY_STARTED          -5201
#define JC_SIP_CONFERENCE_CALL_ALREADY_ENDED            -5202

extern NSString *const kJCSipHandlerErrorDomain;

@interface JCSipHandlerError : JCError

@end
