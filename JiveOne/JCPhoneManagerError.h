//
//  JCPhoneManagerError.h
//  JiveOne
//
//  Created by Robert Barclay on 1/15/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCError.h"

#define JS_PHONE_SIP_NOT_INITIALIZED                -1000
#define JS_PHONE_WIFI_DISABLED                      -1001
#define JS_PHONE_ALREADY_CONNECTING                 -1002
#define JS_PHONE_LINE_IS_NULL                       -1003
#define JC_PHONE_LINE_CONFIGURATION_REQUEST_ERROR   -1004

@interface JCPhoneManagerError : JCError

@end
