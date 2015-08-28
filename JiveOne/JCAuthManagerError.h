//
//  JCAuthManagerError.h
//  Pods
//
//  Created by Robert Barclay on 8/5/15.
//
//

#import "JCAuthError.h"

#define AUTH_MANAGER_CLIENT_ERROR           2000
#define AUTH_MANAGER_PBX_INFO_ERROR         2002
#define AUTH_MANAGER_AUTH_TOKEN_ERROR       2003
#define AUTH_MANAGER_REQUIRES_LOGIN         2004
#define AUTH_MANAGER_REQUIRES_VALIDATION    2005

extern NSString *const kJCAuthManagerErrorDomain;

@interface JCAuthManagerError : JCAuthError

@end
