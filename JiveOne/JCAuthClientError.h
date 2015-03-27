
//  JCAuthenticationClientErrors.h
//  JiveOne
//
//  Created by P Leonard on 3/24/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCError.h"

#define AUTH_CLIENT_INVALID_PARAM             1006
#define AUTH_CLIENT_AUTHENTICATION_ERROR      1007
#define AUTH_CLIENT_NETWORK_ERROR             1008
#define AUTH_CLIENT_TIMEOUT_ERROR             1009
#define AUTH_CLIENT_NO_PBX_ERROR              1010

@interface JCAuthClientError : JCError

@end
