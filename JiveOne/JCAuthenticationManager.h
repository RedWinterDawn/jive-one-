//
//  JCAuthenticationManager.h
//  JiveAppOne
//
//  Created by Eduardo Gueiros on 2/8/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KeychainItemWrapper.h"

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
- (void)logout:(UIViewController *)viewController;
- (NSString *)getAuthenticationToken;
@end
