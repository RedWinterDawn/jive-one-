//
//  JCAutheticationParameters.m
//  JiveOne
//
//  Created by Robert Barclay on 12/16/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCAuthenticationKeychain.h"
#import "JCAuthenticationManagerError.h"

// Keychain
NSString *const kJCAuthenticationManagerKeychainStoreIdentifier  = @"oauth-token";

@interface JCAuthenticationKeychain ()
{
    NSString *_jiveUserId;
}

@end

@implementation JCAuthenticationKeychain

- (BOOL)setAccessToken:(NSString *)accessToken username:(NSString *)username;
{
    if (!username || username.length == 0) {
        [NSException raise:NSInvalidArgumentException format:@"Username null or empty"];
    }
    
    if (!accessToken || accessToken.length == 0) {
        [NSException raise:NSInvalidArgumentException format:@"Access Token null or empty"];
    }
    
    _jiveUserId = username;
    NSMutableDictionary *keychainQuery = [self getKeychainQueryForAccount:username];
    OSStatus result = SecItemDelete((__bridge CFDictionaryRef)keychainQuery);  // Easier to delete than to update.
    if (result == noErr) {
        #if DEBUG
        NSLog(@"Successfully deleted previous store %@ into keychain", username);
        #endif
    }
    
    // Data store
    [keychainQuery setObject:[accessToken dataUsingEncoding:NSUTF8StringEncoding] forKey:(__bridge id)kSecValueData];
    
    #if DEBUG
    NSLog(@"%@", [keychainQuery description]);
    #endif
    
    result = SecItemAdd((__bridge CFDictionaryRef)keychainQuery, NULL);
    if (result == noErr) {
        #if DEBUG
        NSLog(@"Successfully stored access token for %@ into keychain", username);
        #endif
        return YES;
    }
    
    #if DEBUG
    NSLog(@"Failed storing value for keychain");
    #endif
    return NO;
}

-(void)logout
{
    _jiveUserId = nil;
    NSMutableDictionary *keychainQuery = [self getBaseKeychainQuery];
    SecItemDelete((__bridge CFDictionaryRef)keychainQuery);
}

#pragma mark - Getters -

-(NSString *)jiveUserId
{
    if (!_jiveUserId) {
        NSString *value = nil;
        CFDictionaryRef result = nil;
        NSMutableDictionary *keychainQuery = [self getBaseKeychainQuery];
        [keychainQuery setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnAttributes];
        [keychainQuery setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];
        if (SecItemCopyMatching((__bridge CFDictionaryRef)keychainQuery, (CFTypeRef *)&result) == noErr) {
            NSDictionary *items = (__bridge NSDictionary *)result;
            value = [items objectForKey:(__bridge id)kSecAttrAccount];
        }
        
        if (result) {
            CFRelease(result);
        }
        
        #if DEBUG
        NSLog(@"Loaded Jive User Id from keychain: %@", value);
        #endif
        
        _jiveUserId = value;
    }
    return _jiveUserId;
}


-(NSString *)accessToken
{
    NSString *jiveUserId = self.jiveUserId;
    if (!jiveUserId || jiveUserId.length < 1) {
        return nil;
    }
    
    NSString *accessToken = [self loadAccessTokenForAccount:jiveUserId];
    if (accessToken && accessToken.length > 0) {
        return accessToken;
    }
    return nil;
}

-(BOOL)isAuthenticated
{
   return (self.accessToken.length > 0);
}

#pragma mark - Private -

- (NSMutableDictionary *)getBaseKeychainQuery
{
    NSString *bundleIdentifier = [[NSBundle mainBundle] objectForInfoDictionaryKey:(__bridge id)kCFBundleIdentifierKey];
    
    NSString *service = [NSString stringWithFormat:@"%@.%@", bundleIdentifier, kJCAuthenticationManagerKeychainStoreIdentifier];
    return [@{(__bridge id)kSecClass                    : (__bridge id)kSecClassGenericPassword,
              (__bridge id)kSecAttrService              : service,
              (__bridge id)kSecAttrSynchronizable       : (__bridge id)kCFBooleanTrue,
              (__bridge id)kSecAttrAccessible           : (__bridge id)kSecAttrAccessibleAfterFirstUnlock,
              } mutableCopy];
}

- (NSMutableDictionary *)getKeychainQueryForAccount:(NSString *)account
{
    NSMutableDictionary *baseKeyChainQuery = [self getBaseKeychainQuery];
    [baseKeyChainQuery setObject:account forKey:(__bridge id)kSecAttrAccount];
    return baseKeyChainQuery;
}

- (NSString *)loadAccessTokenForAccount:(NSString *)account
{
    NSString *value = nil;
    CFDataRef keyData = NULL;
    NSMutableDictionary *keychainQuery = [self getKeychainQueryForAccount:account];
    [keychainQuery setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];
    [keychainQuery setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];
    if (SecItemCopyMatching((__bridge CFDictionaryRef)keychainQuery, (CFTypeRef *)&keyData) == noErr) {
        @try {
            value = [[NSString alloc] initWithData:(__bridge NSData *)keyData encoding:NSUTF8StringEncoding];
        }
        @catch (NSException *e) {
            NSString *key = [keychainQuery valueForKey:(__bridge id)kSecAttrService];
            NSLog(@"Unarchive of %@ failed: %@", key, e);
            value = nil;
        }
    }
    
    if (keyData) {
        CFRelease(keyData);
    }
    
    return value;
}

@end
