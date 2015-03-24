//
//  JCAuthenticationManager.h
//  JiveAppOne
//
//  Created by Eduardo Gueiros on 2/8/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "User.h"
#import "Line.h"
#import "DID.h"
#import "PBX.h"

extern NSString *const kJCAuthenticationManagerUserLoggedOutNotification;
extern NSString *const kJCAuthenticationManagerUserAuthenticatedNotification;
extern NSString *const kJCAuthenticationManagerUserLoadedMinimumDataNotification;
extern NSString *const kJCAuthenticationManagerLineChangedNotification;

typedef void (^CompletionBlock) (BOOL success, NSError *error);

@interface JCAuthenticationManager : NSObject 

- (void)checkAuthenticationStatus;
- (void)loginWithUsername:(NSString *)username password:(NSString*)password completed:(CompletionBlock)completed;
- (void)logout;

@property (nonatomic, strong) Line *line;
@property (nonatomic, readonly) User *user;
@property (nonatomic, readonly) DID *did;
@property (nonatomic, readonly) PBX *pbx;

@property (nonatomic, readonly) NSString *authToken;
@property (nonatomic, readonly) NSString *jiveUserId;
@property (nonatomic, readonly) BOOL userAuthenticated;
@property (nonatomic, readonly) BOOL userLoadedMinimumData;

// Remember Me
@property (nonatomic) BOOL rememberMe;
@property (nonatomic, readonly) NSString *rememberMeUser;

@property (nonatomic, strong) NSString *deviceToken;

@end

@interface JCAuthenticationManager (Singleton)

+ (JCAuthenticationManager*)sharedInstance;

@end
