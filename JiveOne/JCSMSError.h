//
//  JCSMSError.h
//  JiveOne
//
//  Created by P Leonard on 2/16/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import "JCError.h"


#define SMS_FAILED_CODE_OAUTH                       - 1001
#define SMS_FAILED_CODE_USER_PERMISSION     - 1002
#define SMS_FAILED_CODE_NO_DID                      - 1003
#define SMS_FAILED_CODE_PBX_DISABLED           - 1004
#define SMS_FAILED_CODE_PEER_DISABLED          - 1005
#define SMS_MESSAGE_CAP_REACHED                    - 2001
#define SMS_MESSAGE_CAP_UNDEFINED                - 2002

@interface JCSMSError : JCError

@end
