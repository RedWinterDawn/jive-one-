//
//  JCAuthenticationManager.h
//  JiveAppOne
//
//  Created by Eduardo Gueiros on 2/8/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <JCPhoneModule/JCManager.h>
#import <JCPhoneModule/JCError.h>

@class User;
@class Line;
@class DID;
@class PBX;

extern NSString *const kJCAuthenticationManagerUserRequiresAuthenticationNotification;
extern NSString *const kJCAuthenticationManagerUserWillLogOutNotification;
extern NSString *const kJCAuthenticationManagerUserLoggedOutNotification;
extern NSString *const kJCAuthenticationManagerUserAuthenticatedNotification;
extern NSString *const kJCAuthenticationManagerUserLoadedMinimumDataNotification;
extern NSString *const kJCAuthenticationManagerLineChangedNotification;

@interface JCAuthenticationManager : JCManager

- (void)checkAuthenticationStatus;
- (void)loginWithUsername:(NSString *)username password:(NSString*)password completed:(CompletionHandler)completed;
- (void)logout;

@property (nonatomic, strong) Line *line;       // Selectable
@property (nonatomic, strong) DID *did;         // Selectable
@property (nonatomic, readonly) User *user;
@property (nonatomic, readonly) PBX *pbx;

@property (nonatomic, readonly) NSString *authToken;
@property (nonatomic, readonly) NSString *jiveUserId;
@property (nonatomic, readonly) double exspirationDate;
@property (nonatomic, readonly) BOOL userAuthenticated;
@property (nonatomic, readonly) BOOL userLoadedMinimumData;

// Remember Me
@property (nonatomic) BOOL rememberMe;
@property (nonatomic, readonly) NSString *rememberMeUser;

+ (void)requestAuthentication:(CompletionHandler)completion;
+ (void)requestAuthenticationForUser:(User *)user completion:(CompletionHandler)completion;

@end

#define AUTH_MANAGER_CLIENT_ERROR       2000
#define AUTH_MANAGER_PBX_INFO_ERROR     2002
#define AUTH_MANAGER_AUTH_TOKEN_ERROR   2003

@interface JCAuthenticationManagerError : JCError

@end

@interface UIViewController (AuthenticationManager)

@property (nonatomic, strong) JCAuthenticationManager *authenticationManager;

@end

@interface UIApplication (AuthenticationManager)

@property (nonatomic, strong) JCAuthenticationManager *authenticationManager;

@end
