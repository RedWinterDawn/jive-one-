//
//  JCAuthenticationManager.m
//  JiveAppOne
//
//  Created by Eduardo Gueiros on 2/8/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCAuthenticationManager.h"
#import "JCOsgiClient.h"
#import "JCAccountViewController.h"

@implementation JCAuthenticationManager

+ (JCAuthenticationManager *)sharedInstance
{
    static JCAuthenticationManager* sharedObject = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedObject = [[JCAuthenticationManager alloc] init];
        sharedObject.keychainWrapper = [[KeychainItemWrapper alloc] initWithIdentifier:kJiveAuthStore accessGroup:nil];
    });
    return sharedObject;
}


- (void)didReceiveAuthenticationToken:(NSString *)token
{
    [_keychainWrapper setObject:[NSString stringWithFormat:@"%@", token] forKey:(__bridge id)(kSecAttrAccount)];
    [[NSUserDefaults standardUserDefaults] setObject:token forKey:@"authToken"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    NSLog(@"Token: %@",token);
}

- (void)checkForTokenValidity
{
    [[JCOsgiClient sharedClient] RetrieveConversations:^(id JSON) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kAuthenticationFromTokenSucceeded object:JSON];
    } failure:^(NSError *err) {
        NSLog(@"%@", err);
        [[NSNotificationCenter defaultCenter] postNotificationName:kAuthenticationFromTokenFailed object:err];
    }];
}

- (void)showLoginViewControllerFromViewController:(UIViewController*)viewController completed:(void (^)(bool))completed
{
//    JCWebViewController* webView = [viewController.storyboard instantiateViewControllerWithIdentifier:@"LoginStoryboard"];
//    [viewController presentViewController:webView animated:YES completion:^{
//        completed(YES);
//    }];
    //[viewController performSegueWithIdentifier:@"LoginSegue" sender:nil];
}

// IBAction method for logout is in the JCAccountViewController.m
- (void)logout:(UIViewController *)viewController {
    
    KeychainItemWrapper *wrapper = [[KeychainItemWrapper alloc] initWithIdentifier:kJiveAuthStore accessGroup:nil];
    [wrapper resetKeychainItem];
    
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"authToken"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [[JCOsgiClient sharedClient] clearCookies];
    
    [viewController dismissViewControllerAnimated:YES completion:nil];
    
    
}

@end
