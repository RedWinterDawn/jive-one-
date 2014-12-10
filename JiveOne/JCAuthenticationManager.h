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
#import "User.h"
#import "Line.h"

extern NSString *const kJCAuthenticationManagerUserLoggedOutNotification;
extern NSString *const kJCAuthenticationManagerUserAuthenticatedNotification;
extern NSString *const kJCAuthenticationManagerUserLoadedMinimumDataNotification;
extern NSString *const kJCAuthenticationManagerPbxChangedNotification;
extern NSString *const kJCAuthenticationManagerLineConfigurationChangedNotification;

typedef void (^CompletionBlock) (BOOL success, NSError *error);

@interface JCAuthenticationManager : NSObject 

- (void)loginWithUsername:(NSString *)username password:(NSString*)password completed:(CompletionBlock)completed;
- (void)logout;

@property (nonatomic, strong) User *user;
@property (nonatomic, strong) Line *line;

@property (nonatomic, readonly) NSString *authToken;
@property (nonatomic, readonly) NSString *refreshToken;

// Deprecated Attributes
@property (nonatomic, strong) PBX *pbx __deprecated;
@property (nonatomic, strong) LineConfiguration *lineConfiguration __deprecated;
@property (nonatomic, readonly) NSString *jiveUserId __deprecated;
@property (nonatomic, readonly) NSString *pbxName __deprecated;

@property (nonatomic, readonly) BOOL userAuthenticated;
@property (nonatomic, readwrite) BOOL userLoadedMininumData;
@property (nonatomic) BOOL rememberMe;

-(void)checkAuthenticationStatus;

@end

@interface JCAuthenticationManager (Singleton)

+ (JCAuthenticationManager*)sharedInstance;

@end
