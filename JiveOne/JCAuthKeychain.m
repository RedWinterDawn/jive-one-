//
//  JCAutheticationParameters.m
//  JiveOne
//
//  Created by Robert Barclay on 12/16/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "JCAuthKeychain.h"

@interface JCAuthKeychain () {
    JCAuthInfo *_authInfo;
}

@end

@implementation JCAuthKeychain

- (BOOL)setAuthInfo:(JCAuthInfo *)authInfo error:(NSError *__autoreleasing *)error
{
    if (!authInfo) {
        *error = [NSError errorWithDomain:@"JCAuthKeychainDomain" code:1 userInfo:nil];
        return NO;
    }
    
    NSMutableDictionary *keychainQuery = [self getKeychainQueryForUsername:authInfo.username];
    OSStatus result = SecItemDelete((__bridge CFDictionaryRef)keychainQuery);  // Easier to delete than to update.
    [keychainQuery setObject:authInfo.data forKey:(__bridge id)kSecValueData];
    result = SecItemAdd((__bridge CFDictionaryRef)keychainQuery, NULL);
    if (result == noErr) {
        return YES;
    }
    return NO;
}

-(void)logout
{
    _authInfo = nil;
    NSMutableDictionary *keychainQuery = [self getBaseKeychainQuery];
    SecItemDelete((__bridge CFDictionaryRef)keychainQuery);
}

#pragma mark - Getters -

-(JCAuthInfo *)authInfo
{
    if (_authInfo) {
        return _authInfo;
    }
    
    NSString *username = [self authenticatedUsername];
    if (!username || username.length < 1) {
        return nil;
    }
    
    NSData *data = [self loadAccessTokenDataForUsername:username];
    if (data && data.length > 0) {
        _authInfo = [[JCAuthInfo alloc] initWithData:data];
    }
    return _authInfo;
}

-(BOOL)isAuthenticated
{
    return self.authInfo != nil;
}

#pragma mark - Private -

-(NSString *)authenticatedUsername
{
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
    
    if (!value || value.length < 1) {
        return nil;
    }
    
    return value;
}


- (NSData *)loadAccessTokenDataForUsername:(NSString *)username
{
    NSData *data = nil;
    CFDataRef keyData = NULL;
    NSMutableDictionary *keychainQuery = [self getKeychainQueryForUsername:username];
    [keychainQuery setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];
    [keychainQuery setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];
    if (SecItemCopyMatching((__bridge CFDictionaryRef)keychainQuery, (CFTypeRef *)&keyData) == noErr) {
        data = (__bridge NSData *)keyData;
        if (keyData) {
            CFRelease(keyData);
        }
    }
    return data;
}

- (NSMutableDictionary *)getKeychainQueryForUsername:(NSString *)username
{
    NSMutableDictionary *baseKeyChainQuery = [self getBaseKeychainQuery];
    [baseKeyChainQuery setObject:username forKey:(__bridge id)kSecAttrAccount];
    return baseKeyChainQuery;
}

- (NSMutableDictionary *)getBaseKeychainQuery
{
    NSString *bundleIdentifier = [[NSBundle mainBundle] objectForInfoDictionaryKey:(__bridge id)kCFBundleIdentifierKey];
    static NSString *keychainIdentifier = @"oauth-token";
    NSString *service = [NSString stringWithFormat:@"%@.%@", bundleIdentifier, keychainIdentifier];
    return [@{(__bridge id)kSecClass                    : (__bridge id)kSecClassGenericPassword,
              (__bridge id)kSecAttrService              : service,
              (__bridge id)kSecAttrSynchronizable       : (__bridge id)kCFBooleanTrue,
              (__bridge id)kSecAttrAccessible           : (__bridge id)kSecAttrAccessibleAfterFirstUnlock,
              } mutableCopy];
}


@end
