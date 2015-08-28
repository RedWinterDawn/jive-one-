//
//  JCAuthManager.h
//  JiveOne
//
//  Created by Robert Barclay on 8/28/15.
//  Copyright (c) 2015 Jive Communications, Inc. All rights reserved.
//

#import <JCPhoneModule/JCPhoneModule.h>

#import "JCAuthSettings.h"
#import "JCAuthKeychain.h"
#import "JCAuthManagerError.h"

typedef void(^JCAuthCompletionHandler)(BOOL success, NSString *username, NSError *error);

extern NSString *const kJCAuthenticationManagerUserRequiresAuthenticationNotification;
extern NSString *const kJCAuthenticationManagerUserWillLogOutNotification;
extern NSString *const kJCAuthenticationManagerUserLoggedOutNotification;
extern NSString *const kJCAuthenticationManagerUserAuthenticatedNotification;
extern NSString *const kJCAuthenticationManagerAuthenticationFailedNotification;

@interface JCAuthManager : JCManager
{
    JCAuthKeychain *_keychain;
}

- (instancetype)initWithKeychain:(JCAuthKeychain *)keychain setting:(JCAuthSettings *)settings;

- (void)checkAuthenticationStatus:(JCAuthCompletionHandler)completed;
- (void)loginWithUsername:(NSString *)username password:(NSString*)password completed:(JCAuthCompletionHandler)completed;
- (void)logout;

+ (void)requestAuthenticationForUsername:(NSString *)username completion:(JCAuthCompletionHandler)completion;

@property (nonatomic, readonly) JCAuthSettings *settings;
@property (nonatomic, readonly) JCAuthToken *authToken;
@property (nonatomic, readonly) BOOL userAuthenticated;

@end