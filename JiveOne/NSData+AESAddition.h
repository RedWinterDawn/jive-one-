//
//  NSData+AESAddition.h
//  JiveOne
//
//  Created by Robert Barclay on 12/15/14.
//  Copyright (c) 2014 Jive Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (AESAddition)

+ (NSData *)AES256EncryptString:(NSString *)string key:(NSString *)key;
+ (NSData *)AES256EncryptString:(NSString *)string key:(NSString *)key encoding:(NSStringEncoding)encoding;


+ (NSData *)AES256EncryptData:(NSData *)data key:(NSString *)key;
+ (NSData *)AES265DecryptData:(NSData *)data Key:(NSString *)key;

- (NSData *)AES256EncryptWithKey:(NSString *)key;
- (NSData *)AES256DecryptWithKey:(NSString *)key;

@end


@interface NSString (AESAddition)

+ (NSString *)AES256DecryptData:(NSData *)data key:(NSString *)key encoding:(NSStringEncoding)encoding;
+ (NSString *)AES256DecryptData:(NSData *)data key:(NSString *)key;

@end