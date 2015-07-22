//
//  JCAuthenticationManager.h
//  JiveAppOne
//
//  Created by Eduardo Gueiros on 2/8/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "JCManager.h"

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

typedef void (^CompletionBlock) (BOOL success, NSError *error);

@interface JCAuthenticationManager : JCManager

- (void)checkAuthenticationStatus;
- (void)loginWithUsername:(NSString *)username password:(NSString*)password completed:(CompletionBlock)completed;
- (void)logout;

@property (nonatomic, strong) Line *line;
@property (nonatomic, strong) DID *did;
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

//@property (nonatomic, strong) NSString *deviceToken;

+ (void)requestAuthentication:(CompletionHandler)completion;
+ (void)requestAuthenticationForUser:(User *)user completion:(CompletionHandler)completion;

@end

@interface JCAuthenticationManager (Singleton)

+ (JCAuthenticationManager*)sharedInstance;

@end

@interface UIViewController (AuthenticationManager)

@property (nonatomic, strong) JCAuthenticationManager *authenticationManager;

@end
