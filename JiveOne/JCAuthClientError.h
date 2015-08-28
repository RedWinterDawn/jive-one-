//
//  JCAuthClientError.h
//  Pods
//
//  Created by Robert Barclay on 8/5/15.
//
//

#import "JCAuthError.h"

#define AUTH_CLIENT_INVALID_REQUEST_PARAMETERS  2000
#define AUTH_CLIENT_AUTHENTICATION_ERROR        2001
#define AUTH_CLIENT_NETWORK_ERROR               2002

@interface JCAuthClientError : JCAuthError

@end
