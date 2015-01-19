//
//  JCSipHandlerError.h
//  JiveOne
//
//  Created by Robert Barclay on 1/14/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCError.h"
#import <PortSIPLib/PortSIPSDK.h>

#define JC_SIP_REGISTER_LINE_IS_EMPTY                   -1000
#define JC_SIP_REGISTER_LINE_CONFIGURATION_IS_EMPTY     -1001
#define JC_SIP_REGISTER_LINE_PBX_IS_EMPTY               -1002
#define JC_SIP_REGISTER_USER_IS_EMPTY                   -1003
#define JC_SIP_REGISTER_SERVER_IS_EMPTY                 -1004
#define JC_SIP_REGISTER_PASSWORD_IS_EMPTY               -1005
#define JC_SIP_REGISTER_CALLER_ID_IS_EMPTY              -1006

#define JC_SIP_LINE_SESSION_IS_EMPTY                    -2000
#define JC_SIP_CONFERENCE_CALL_ALREADY_STARTED          -2001
#define JC_SIP_CONFERENCE_CALL_ALREADY_ENDED            -2002

extern NSString *const kJCSipHandlerErrorDomain;

@interface JCSipHandlerError : JCError

@end
