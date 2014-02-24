//
//  JCAuthenticationManager.h
//  JiveAppOne
//
//  Created by Eduardo Gueiros on 2/8/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KeychainItemWrapper.h"

@interface JCAuthenticationManager : NSObject

@property (strong, nonatomic) KeychainItemWrapper *keychainWrapper;

+ (JCAuthenticationManager*)sharedInstance;
- (void)showLoginViewControllerFromViewController:(UIViewController*)viewController completed:(void (^)(bool object))completed;

- (void)didReceiveAuthenticationToken:(NSString*)token;
- (void)checkForTokenValidity;
- (void)logout:(UIViewController *)viewController;

@end
