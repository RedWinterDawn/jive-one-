//
//  JCKeychain.m
//  JiveOne
//
//  Created by Robert Barclay on 12/22/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#define CHECK_OSSTATUS_ERROR(x) (x == noErr) ? YES : NO

#import "JCKeychain.h"

@implementation JCKeychain

+ (NSMutableDictionary *)getKeychainQuery:(NSString *)key
{
    // see http://developer.apple.com/library/ios/#DOCUMENTATION/Security/Reference/keychainservices/Reference/reference.html
    return [@{(__bridge id)kSecClass                    : (__bridge id)kSecClassGenericPassword,
              (__bridge id)kSecAttrAccount              : @"",
              (__bridge id)kSecAttrService              : key,
              (__bridge id)kSecAttrAccessible           : (__bridge id)kSecAttrAccessibleAfterFirstUnlock,
              (__bridge id)kSecAttrSynchronizable       : (__bridge id)kCFBooleanTrue
              } mutableCopy];
}

+ (BOOL)saveValue:(id)data forKey:(NSString *)key
{
    NSMutableDictionary *keychainQuery = [self getKeychainQuery:key];
    SecItemDelete((__bridge CFDictionaryRef)keychainQuery);
    
    [keychainQuery setObject:[NSKeyedArchiver archivedDataWithRootObject:data] forKey:(__bridge id)kSecValueData];
    
    OSStatus result = SecItemAdd((__bridge CFDictionaryRef)keychainQuery, NULL);
    BOOL sucess = CHECK_OSSTATUS_ERROR(result);
    if (sucess) {
        NSLog(@"Successfully stored value into keychain");
    }
    return sucess;
}

+ (BOOL)deleteValueForKey:(NSString *)key
{
    NSMutableDictionary *keychainQuery = [self getKeychainQuery:key];
    OSStatus result = SecItemDelete((__bridge CFDictionaryRef)keychainQuery);
    return CHECK_OSSTATUS_ERROR(result);
}

+ (id)loadValueForKey:(NSString *)key
{
    id value = nil;
    CFDataRef keyData = NULL;
    NSMutableDictionary *keychainQuery = [self getKeychainQuery:key];
    [keychainQuery setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];
    [keychainQuery setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];
    
    if (SecItemCopyMatching((__bridge CFDictionaryRef)keychainQuery, (CFTypeRef *)&keyData) == noErr) {
        @try {
            value = [NSKeyedUnarchiver unarchiveObjectWithData:(__bridge NSData *)keyData];
        }
        @catch (NSException *e) {
            NSString *key = [keychainQuery valueForKey:(__bridge id)kSecAttrService];
            NSLog(@"Unarchive of %@ failed: %@", key, e);
            value = nil;
        }
        @finally {}
    }
    
    if (keyData) {
        CFRelease(keyData);
    }
    
    return value;
}

@end
