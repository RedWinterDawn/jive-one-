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
NSString *const kJCAuthenticationManagerKeychainStoreIdentifier         = @"oauth-token";
NSString *const kJCAuthenticationManagerKeychainTokenKey                = @"token";
NSString *const kJCAuthenticationManagerKeychainExpirationKey           = @"expirationDate";
NSString *const kJCAuthenticationManagerKeychainAuthenticationDateKey   = @"authenticationDate";


@interface JCAuthenticationKeychain ()
{
    NSString *_jiveUserId;
    NSDictionary *_accessData;
}

@property (nonatomic, readonly) NSDictionary *accessData;

@end

@implementation JCAuthenticationKeychain

- (BOOL)setAccessToken:(NSString *)accessToken username:(NSString *)username expiration:(NSDate *)expiration
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
    
    NSDictionary *accessData = @{kJCAuthenticationManagerKeychainTokenKey: accessToken,
                                 kJCAuthenticationManagerKeychainAuthenticationDateKey: [NSDate date],
                                 kJCAuthenticationManagerKeychainExpirationKey: expiration};
    _accessData = accessData;
    
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:accessData];
    [keychainQuery setObject:data forKey:(__bridge id)kSecValueData];
    
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
    _accessData = nil;
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
        _jiveUserId = value;
    }
    return _jiveUserId;
}


-(NSString *)accessToken
{
    NSString *accessToken = [self.accessData stringValueForKey:kJCAuthenticationManagerKeychainTokenKey];
    if (accessToken && accessToken.length > 0) {
         return accessToken;
    }
    return nil;
}

-(NSDate *)authenticationDate
{
    id object = [self.accessData objectForKey:kJCAuthenticationManagerKeychainAuthenticationDateKey];
    if (object && [object isKindOfClass:[NSDate class]]) {
        return (NSDate *)object;
    }
    return nil;
}

-(NSDate  *)expirationDate
{
    id object = [self.accessData objectForKey:kJCAuthenticationManagerKeychainExpirationKey];
    if (object && [object isKindOfClass:[NSDate class]]) {
        return (NSDate *)object;
    }
    return nil;
}

-(BOOL)isAuthenticated
{
   return (self.accessToken.length > 0);
}

#pragma mark - Private -

-(NSDictionary *)accessData
{
    if (_accessData) {
        return _accessData;
    }
    
    NSString *jiveUserId = self.jiveUserId;
    if (!jiveUserId || jiveUserId.length < 1) {
        return nil;
    }
    
    _accessData = [self loadAccessTokenForAccount:jiveUserId];
    return _accessData;
}

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

- (NSDictionary *)loadAccessTokenForAccount:(NSString *)account
{
    NSDictionary *data = nil;
    CFDataRef keyData = NULL;
    NSMutableDictionary *keychainQuery = [self getKeychainQueryForAccount:account];
    [keychainQuery setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];
    [keychainQuery setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];
    if (SecItemCopyMatching((__bridge CFDictionaryRef)keychainQuery, (CFTypeRef *)&keyData) == noErr) {
        @try {
            id object = [NSKeyedUnarchiver unarchiveObjectWithData:(__bridge NSData *)keyData];
            if ([object isKindOfClass:[NSDictionary class]]) {
                data = (NSDictionary *) object;
            }
        }
        @catch (NSException *e) {
            NSString *key = [keychainQuery valueForKey:(__bridge id)kSecAttrService];
            NSLog(@"Unarchive of %@ failed: %@", key, e);
            data = nil;
        }
    }
    
    if (keyData) {
        CFRelease(keyData);
    }
    
    return data;
}

@end
