//
//  JCAuthenticationManager.h
//  JiveAppOne
//
//  Created by Eduardo Gueiros on 2/8/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KeychainItemWrapper.h"

#import "PBX+Custom.h"
#import "Lines+Custom.h"
#import "LineConfiguration+Custom.h"

@class JCAuthenticationManager;

@interface JCAuthenticationManager : NSObject <UIWebViewDelegate>
typedef void (^CompletionBlock) (BOOL success, NSError *error);
@property (strong, nonatomic) KeychainItemWrapper *keychainWrapper;
@property (nonatomic, copy) CompletionBlock completionBlock;
+ (JCAuthenticationManager*)sharedInstance;

- (void)loginWithUsername:(NSString *)username password:(NSString*)password completed:(CompletionBlock)completed;


- (void)didReceiveAuthenticationToken:(NSDictionary *)token;
- (BOOL)userAuthenticated;
- (BOOL)userLoadedMininumData;
- (void)setUserLoadedMinimumData:(BOOL)loaded;
- (void)setRememberMe:(BOOL)remember;
- (BOOL)getRememberMe;
- (void)checkForTokenValidity;
- (void)logout;
- (NSString *)getAuthenticationToken;

@property (nonatomic, readonly) PBX *pbx;
@property (nonatomic, readonly) Lines *line;
@property (nonatomic, readonly) LineConfiguration *lineConfiguration;

@property (nonatomic, readonly) NSString *userName;
@property (nonatomic, readonly) NSString *lineDisplayName;
@property (nonatomic, readonly) NSString *lineExtension;
@property (nonatomic, readonly) NSString *pbxName;


@end
