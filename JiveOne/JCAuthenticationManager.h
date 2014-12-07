//
//  JCAuthenticationManager.h
//  JiveAppOne
//
//  Created by Eduardo Gueiros on 2/8/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PBX+Custom.h"
#import "Lines+Custom.h"
#import "LineConfiguration+Custom.h"

extern NSString *const kJCAuthenticationManagerUserLoggedOutNotification;
extern NSString *const kJCAuthenticationManagerUserAuthenticatedNotification;
extern NSString *const kJCAuthenticationManagerUserLoadedMinimumDataNotification;
extern NSString *const kJCAuthenticationManagerLineConfigurationChangedNotification;

typedef void (^CompletionBlock) (BOOL success, NSError *error);

@interface JCAuthenticationManager : NSObject 

- (void)loginWithUsername:(NSString *)username password:(NSString*)password completed:(CompletionBlock)completed;
- (void)logout;

@property (nonatomic, readonly) PBX *pbx;
@property (nonatomic, strong) LineConfiguration *lineConfiguration;

@property (nonatomic, readonly) NSString *jiveUserId;
@property (nonatomic, readonly) NSString *pbxName;

@property (nonatomic, readonly) NSString *authToken;
@property (nonatomic, readonly) NSString *refreshToken;

@property (nonatomic, readonly) BOOL userAuthenticated;
@property (nonatomic, readwrite) BOOL userLoadedMininumData;
@property (nonatomic) BOOL rememberMe;

-(void)checkAuthenticationStatus;

@end

@interface JCAuthenticationManager (Singleton)

+ (JCAuthenticationManager*)sharedInstance;

@end
