//
//  JCAutheticationParameters.m
//  JiveOne
//
//  Created by Robert Barclay on 12/16/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCAuthenticationStore.h"
#import "KeychainItemWrapper.h"
#import "JCAuthenticationManagerError.h"

// Keychain
NSString *const kJCAuthenticationManagerKeychainStoreIdentifier  = @"keyjiveauthstore";

NSString *const kJCAuthenticationManagerAccessTokenKey  = @"access_token";
NSString *const kJCAuthenticationManagerRefreshTokenKey = @"refresh_token";
NSString *const kJCAuthenticationManagerUsernameKey     = @"username";
NSString *const kJCAuthenticationManagerRememberMeKey   = @"remberMe";

@interface JCAuthenticationStore ()
{
    KeychainItemWrapper *_keychainWrapper;
}

@end

@implementation JCAuthenticationStore

-(instancetype)init
{
    self = [super init];
    if (self) {
        _keychainWrapper = [[KeychainItemWrapper alloc] initWithIdentifier:kJCAuthenticationManagerKeychainStoreIdentifier accessGroup:nil];
        if (self.accessToken == self.jiveUserId) {
            [_keychainWrapper resetKeychainItem];
        }
    }
    return self;
}

-(void)setAuthToken:(NSDictionary *)authToken
{
    NSString *username = [authToken stringValueForKey:kJCAuthenticationManagerUsernameKey];
    if (!username || username.length == 0) {
        [NSException raise:NSInvalidArgumentException format:@"Username null or empty"];
    }
    
    NSString *accessToken = [authToken stringValueForKey:kJCAuthenticationManagerAccessTokenKey];
    if (!accessToken || accessToken.length == 0) {
        [NSException raise:NSInvalidArgumentException format:@"Access Token null or empty"];
    }
    
    NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    
    [_keychainWrapper setObject:appName forKey:(__bridge id)kSecAttrService];
    [_keychainWrapper setObject:(__bridge id)(kSecAttrAccessibleAfterFirstUnlock) forKey:(__bridge id)(kSecAttrAccessible)];
    [_keychainWrapper setObject:username forKey:(__bridge id)(kSecAttrAccount)];
    [_keychainWrapper setObject:accessToken forKey:(__bridge id)(kSecValueData)];
}

-(void)logout
{
    [_keychainWrapper resetKeychainItem];
}

#pragma mark - Getters -

-(NSString *)accessToken
{
    NSString *authToken = [_keychainWrapper objectForKey:(__bridge id)(kSecValueData)];
    if ([authToken isKindOfClass:[NSString class]] && authToken.length > 0) {
        return authToken;
    }
    return nil;
}

-(NSString *)jiveUserId
{
    NSString *jiveUserId = [_keychainWrapper objectForKey:(__bridge id)(kSecAttrAccount)];
    if ([jiveUserId isKindOfClass:[NSString class]] && jiveUserId.length > 0) {
        return jiveUserId;
    }
    return nil;
}

-(BOOL)isAuthenticated
{
    if (self.accessToken && self.jiveUserId) {
        return true;
    }
    return false;
}




@end
