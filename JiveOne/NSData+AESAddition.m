//
//  NSData+AESAddition.m
//  JiveOne
//
//  Created by Robert Barclay on 12/15/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import "NSData+AESAddition.h"
#import <CommonCrypto/CommonCryptor.h>

@implementation NSData (AESAddition)

+ (NSData *)AES256EncryptString:(NSString *)string key:(NSString *)key
{
    return [NSData AES256EncryptString:string key:key encoding:NSUTF8StringEncoding];
}

+ (NSData *)AES256EncryptString:(NSString *)string key:(NSString *)key encoding:(NSStringEncoding)encoding
{
    return [[string dataUsingEncoding:encoding] AES256EncryptWithKey:key];
}

+ (NSData *)AES256EncryptData:(NSData *)data key:(NSString *)key
{
    return [data AES256EncryptWithKey:key];
}

+ (NSData *)AES265DecryptData:(NSData *)data Key:(NSString *)key
{
    return [data AES256DecryptWithKey:key];
}

- (NSData *)AES256EncryptWithKey:(NSString *)key
{
    // 'key' should be 32 bytes for AES256, will be null-padded otherwise
    char keyPtr[kCCKeySizeAES256 + 1]; // room for terminator (unused)
    bzero(keyPtr, sizeof(keyPtr)); // fill with zeroes (for padding)
    
    // fetch key data
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    
    NSUInteger dataLength = [self length];
    
    // Check to see if we have length. if we do not have length, return nil.
    if (dataLength == 0)
        return nil;
    
    //See the doc: For block ciphers, the output size will always be less than or
    //equal to the input size plus the size of one block.
    //That's why we need to add the size of one block here
    size_t bufferSize           = dataLength + kCCBlockSizeAES128;
    void* buffer                = malloc(bufferSize);
    
    size_t numBytesEncrypted    = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding,
                                          keyPtr, kCCKeySizeAES256,
                                          NULL /* initialization vector (optional) */,
                                          [self bytes], dataLength, /* input */
                                          buffer, bufferSize, /* output */
                                          &numBytesEncrypted);
    
    if (cryptStatus == kCCSuccess)
    {
        //the returned NSData takes ownership of the buffer and will free it on deallocation
        return [NSData dataWithBytesNoCopy:buffer length:numBytesEncrypted];
    }
    
    free(buffer); //free the buffer;
    return nil;
}

- (NSData *)AES256DecryptWithKey:(NSString *)key
{
    // 'key' should be 32 bytes for AES256, will be null-padded otherwise
    char keyPtr[kCCKeySizeAES256 + 1]; // room for terminator (unused)
    bzero(keyPtr, sizeof(keyPtr)); // fill with zeroes (for padding)
    
    // fetch key data
    [key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    
    NSUInteger dataLength = [self length];
    if (dataLength == 0)
        return nil;
    
    //See the doc: For block ciphers, the output size will always be less than or
    //equal to the input size plus the size of one block.
    //That's why we need to add the size of one block here
    size_t bufferSize           = dataLength + kCCBlockSizeAES128;
    void* buffer                = malloc(bufferSize);
    
    size_t numBytesDecrypted    = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding,
                                          keyPtr, kCCKeySizeAES256,
                                          NULL /* initialization vector (optional) */,
                                          [self bytes], dataLength, /* input */
                                          buffer, bufferSize, /* output */
                                          &numBytesDecrypted);
    
    if (cryptStatus == kCCSuccess)
    {
        //the returned NSData takes ownership of the buffer and will free it on deallocation
        return [NSData dataWithBytesNoCopy:buffer length:numBytesDecrypted];
    }
    
    free(buffer); //free the buffer;
    return nil;
}

@end

@implementation NSString (AESAddition)

+ (NSString *)AES256DecryptData:(NSData *)data key:(NSString *)key encoding:(NSStringEncoding)encoding
{
    return [[NSString alloc] initWithData:[NSData AES265DecryptData:data Key:key] encoding:encoding];
}

+ (NSString *)AES256DecryptData:(NSData *)data key:(NSString *)key
{
    return [NSString AES256DecryptData:data key:key encoding:NSUTF8StringEncoding];
}

@end
