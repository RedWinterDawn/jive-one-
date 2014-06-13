//
//  JCAuthenticationManager.h
//  JiveAppOne
//
//  Created by Eduardo Gueiros on 2/8/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KeychainItemWrapper.h"
#import "JCRESTClient.h"

@class JCAuthenticationManager;

@interface JCAuthenticationManager : NSObject 

@property (strong, nonatomic) KeychainItemWrapper *keychainWrapper;

+ (JCAuthenticationManager*)sharedInstance;

- (void)loginWithUsername:(NSString *)username password:(NSString*)password completed:(void (^)(BOOL success, NSError *error)) completed;
- (void)setClient:(JCRESTClient *)client;
- (void)didReceiveAuthenticationToken:(NSDictionary *)token;
- (BOOL)userAuthenticated;
- (BOOL)userLoadedMininumData;
- (void)setUserLoadedMinimumData:(BOOL)loaded;
- (void)checkForTokenValidity;
- (void)logout:(UIViewController *)viewController;
- (NSString *)getAuthenticationToken;
@end
